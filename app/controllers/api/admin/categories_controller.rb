module Api
  module Admin
    class CategoriesController < BaseController
      def index
        categories = Category.order(:name)
        render json: categories.map { |c| serialize_category(c) }
      end

      def create
        category = Category.new(category_params)

        if category.save
          render json: serialize_category(category), status: :created
        else
          render json: { errors: category.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        category = Category.find_by!(slug: params[:slug])

        if category.update(category_params)
          render json: serialize_category(category)
        else
          render json: { errors: category.errors.full_messages }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Categoria não encontrada" }, status: :not_found
      end

      def destroy
        category = Category.find_by!(slug: params[:slug])

        if category.products.exists?
          render json: { error: "Não é possível eliminar uma categoria com produtos associados" },
                 status: :unprocessable_entity
          return
        end

        category.destroy!
        head :no_content
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Categoria não encontrada" }, status: :not_found
      end

      private

      def category_params
        params.require(:category).permit(:name, :slug)
      end

      def serialize_category(category)
        {
          id: category.id,
          slug: category.slug,
          name: category.name,
          product_count: category.products.count
        }
      end
    end
  end
end
