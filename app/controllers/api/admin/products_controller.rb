module Api
  module Admin
    class ProductsController < BaseController
      def index
        products = Product.includes(:category, :variants).with_attached_images.order(:name)
        products = products.where("products.name ILIKE ?", "%#{params[:q]}%") if params[:q].present?

        render json: products.map { |p| serialize_product(p) }
      end

      def show
        product = Product.includes(:category, :variants).with_attached_images.find(params[:id])
        render json: serialize_product(product)
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Produto não encontrado" }, status: :not_found
      end

      # POST /api/admin/products
      # Accepts JSON or multipart/form-data. Images must be sent as files in
      # multipart form (`product[images][]`). `image_colors` maps each color to
      # the image indices it belongs to (e.g. { "#D4916E": [0, 1] }).
      def create
        product = Product.new(product_attributes)

        ActiveRecord::Base.transaction do
          product.save!
          attach_images(product)
          sync_variants(product, variants_params)
          product.save!
        end

        render json: serialize_product(product), status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      rescue ActiveRecord::RecordNotUnique
        render json: { errors: ["Já existe uma variante com o mesmo tamanho e cor"] },
               status: :unprocessable_entity
      end

      # PATCH /api/admin/products/:id
      # Same payload as create. Variants are synchronized by id: entries with an
      # existing id are updated, entries without an id are created, and variants
      # omitted (or sent with `_destroy`) are removed unless referenced by
      # carts or orders. Images sent in `product[images][]` are appended;
      # `product[remove_image_ids][]` purges existing attachments.
      def update
        product = Product.includes(:variants).with_attached_images.find(params[:id])

        ActiveRecord::Base.transaction do
          product.assign_attributes(product_attributes)
          remove_images(product)
          attach_images(product)
          sync_variants(product, variants_params)
          product.save!
        end

        render json: serialize_product(product)
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Produto não encontrado" }, status: :not_found
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      rescue ActiveRecord::RecordNotUnique
        render json: { errors: ["Já existe uma variante com o mesmo tamanho e cor"] },
               status: :unprocessable_entity
      end

      def destroy
        product = Product.find(params[:id])

        if product_referenced?(product)
          render json: { error: "Não é possível eliminar um produto associado a carrinhos ou pedidos" },
                 status: :unprocessable_entity
          return
        end

        product.destroy!
        head :no_content
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Produto não encontrado" }, status: :not_found
      end

      private

      def product_params
        params.require(:product).permit(
          :name, :price, :category_id,
          sizes: [],
          colors: [],
          image_colors: {},
          variants: [:id, :size, :color, :stock, :sku, :_destroy],
          images: [],
          remove_image_ids: []
        )
      end

      def product_attributes
        attrs = product_params.except(:variants, :images, :remove_image_ids)

        if product_params[:image_colors].present?
          # multipart form data sends the indices as strings ("0", "1").
          attrs[:image_colors] = product_params[:image_colors].transform_values do |indices|
            Array(indices).map(&:to_i)
          end
        end

        attrs
      end

      def variants_params
        product_params[:variants]
      end

      def attach_images(product)
        files = product_params[:images]
        return if files.blank?

        files = [files] unless files.is_a?(Array)
        files.each do |file|
          unless file.respond_to?(:original_filename)
            product.errors.add(:images, "devem ser enviadas como ficheiros (multipart/form-data)")
            raise ActiveRecord::RecordInvalid, product
          end
          product.images.attach(file)
        end
      end

      def remove_images(product)
        ids = product_params[:remove_image_ids]
        return if ids.blank?

        ids = [ids] unless ids.is_a?(Array)
        product.images.attachments.where(id: ids).each(&:purge)
      end

      # Keeps variants in sync with the submitted list. Missing variants are
      # destroyed (unless referenced by carts/orders), submitted ids are
      # updated and entries without an id are created.
      def sync_variants(product, submitted)
        return if submitted.blank?

        submitted_ids = submitted.filter_map { |vp| vp[:id]&.to_s }

        product.variants.to_a.each do |variant|
          next if submitted_ids.include?(variant.id.to_s)

          if variant_referenced?(variant)
            product.errors.add(:base, variant_in_use_message(variant))
          else
            variant.destroy
          end
        end

        submitted.each do |vp|
          if destroy_requested?(vp)
            remove_submitted_variant(product, vp)
            next
          end

          variant =
            if vp[:id].present?
              product.variants.find { |v| v.id == vp[:id].to_i }
            else
              product.variants.build
            end

          if variant.nil?
            product.errors.add(:base, "Variante com id #{vp[:id]} não pertence a este produto")
            next
          end

          variant.assign_attributes(vp.permit(:size, :color, :stock, :sku))
          variant.save! if variant.changed?
        end

        product.variants.reject(&:destroyed?).group_by { |v| [v.size.to_s.strip, v.color.to_s.strip] }.each do |(size, color), duplicates|
          next if duplicates.size < 2

          product.errors.add(:base, "Variante duplicada: #{size} / #{color}")
        end
      end

      def remove_submitted_variant(product, vp)
        return if vp[:id].blank?

        variant = product.variants.find { |v| v.id == vp[:id].to_i }
        return unless variant

        if variant_referenced?(variant)
          product.errors.add(:base, variant_in_use_message(variant))
        else
          variant.destroy
        end
      end

      def destroy_requested?(vp)
        vp[:_destroy] == true || %w[1 true].include?(vp[:_destroy].to_s)
      end

      def variant_referenced?(variant)
        CartItem.exists?(variant_id: variant.id) || OrderItem.exists?(variant_id: variant.id)
      end

      def product_referenced?(product)
        return true if OrderItem.exists?(product_id: product.id)

        product.variants.any? { |v| variant_referenced?(v) }
      end

      def variant_in_use_message(variant)
        "Não é possível remover a variante #{variant.size} / #{variant.color}: está associada a carrinhos ou pedidos"
      end

      def serialize_product(product)
        {
          id: product.id,
          name: product.name,
          price: product.price.to_f,
          sizes: product.sizes,
          colors: product.colors,
          image_colors: product.image_colors,
          category: { slug: product.category.slug, name: product.category.name },
          category_id: product.category_id,
          variants: product.variants.map do |v|
            { id: v.id, size: v.size, color: v.color, stock: v.stock, sku: v.sku }
          end,
          images: product.images.map do |img|
            { id: img.id, url: url_for(img), filename: img.filename.to_s }
          end
        }
      end
    end
  end
end
