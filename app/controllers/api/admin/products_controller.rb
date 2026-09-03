module Api
  module Admin
    class ProductsController < BaseController
      def index
        products = Product.includes(:category, :variants).with_attached_images
        products = products.where("products.name ILIKE ?", "%#{params[:q]}%") if params[:q].present?
        products = products.where(categories: { slug: params[:category] }).references(:category) if params[:category].present?
        products = apply_sort(products)

        page, meta = paginate(products)

        render json: {
          data: page.map { |p| serialize_product(p) },
          meta: meta
        }
      end

      def show
        product = Product.includes(:category, :variants).with_attached_images.find(params[:id])
        render json: serialize_product(product)
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Produto não encontrado" }, status: :not_found
      end

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

      def update
        product = Product.includes(:variants).with_attached_images.find(params[:id])

        ActiveRecord::Base.transaction do
          product.assign_attributes(product_attributes)
          remove_images(product)
          attach_images(product)
          sync_variants(product, variants_params)
          product.save!
        end

        render json: serialize_product(product.reload)
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

      SORTABLE_FIELDS = %w[name price category stock variants_count].freeze

      def apply_sort(products)
        field = params[:sort]
        return products.order(:name) unless SORTABLE_FIELDS.include?(field)

        direction = params[:direction] == "desc" ? "DESC" : "ASC"
        tiebreaker = "products.name ASC"

        case field
        when "name"
          products.order("products.name #{direction}, products.id ASC")
        when "price"
          products.order("products.price #{direction}, products.name ASC")
        when "category"
          products.joins(:category).order("categories.name #{direction}, #{tiebreaker}")
        when "stock"
          products
            .select("products.*, (SELECT COALESCE(SUM(variants.stock), 0) FROM variants WHERE variants.product_id = products.id) AS total_stock")
            .order("total_stock #{direction}, #{tiebreaker}")
        when "variants_count"
          products
            .select("products.*, (SELECT COUNT(*) FROM variants WHERE variants.product_id = products.id) AS variants_count")
            .order("variants_count #{direction}, #{tiebreaker}")
        end
      end

      def product_params
        source = params.require(:product)
        permitted = source.permit(
          :name, :price, :category_id,
          :variants, :image_colors,
          sizes: [],
          colors: [],
          images: [],
          remove_image_ids: []
        )

        variants = source[:variants]
        if variants.is_a?(String)
          variants = JSON.parse(variants)
        end

        if variants.is_a?(Array)
          permitted[:variants] = variants.map do |vp|
            vp = ActionController::Parameters.new(vp) unless vp.is_a?(ActionController::Parameters)
            vp.permit(:id, :size, :color, :stock, :sku, :_destroy)
          end
        end

        image_colors = source[:image_colors]
        if image_colors.is_a?(String)
          image_colors = JSON.parse(image_colors)
        end

        if image_colors.present?
          image_colors = image_colors.to_unsafe_h if image_colors.is_a?(ActionController::Parameters)
          permitted[:image_colors] = image_colors
        end

        permitted.to_unsafe_h
      rescue JSON::ParserError
        invalid = Product.new
        invalid.errors.add(:base, "product[variants] e product[image_colors] devem conter JSON válido")
        raise ActiveRecord::RecordInvalid, invalid
      end

      def product_attributes
        attrs = product_params.except(:variants, :images, :remove_image_ids)

        if product_params[:image_colors].present?
          attrs[:image_colors] = product_params[:image_colors].transform_values do |indices|
            Array(indices).map(&:to_i)
          end
        end

        if (attrs[:sizes].blank? || attrs[:colors].blank?) && variants_params.present?
          submitted = variants_params.reject { |vp| destroy_requested?(vp) }
          attrs[:sizes] = submitted.map { |vp| vp[:size].to_s.strip }.reject(&:empty?).uniq if attrs[:sizes].blank?
          attrs[:colors] = submitted.map { |vp| vp[:color].to_s.strip }.reject(&:empty?).uniq if attrs[:colors].blank?
        end

        attrs
      end

      def variants_params
        submitted = product_params[:variants]
        return nil if submitted.blank?

        submitted.map do |vp|
          vp.is_a?(ActionController::Parameters) ? vp : ActionController::Parameters.new(vp)
        end
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
