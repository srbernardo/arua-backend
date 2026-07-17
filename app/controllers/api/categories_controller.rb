module Api
  class CategoriesController < ApplicationController
    def index
      categories = Category.all.order(:name)
      render json: categories.map { |c| serialize_category(c) }
    end

    def show
      category = Category.find_by!(slug: params[:slug])
      render json: {
        **serialize_category(category),
        products: category.products.map { |p| serialize_product(p) }
      }
    end

    private

    def serialize_category(category)
      { id: category.slug, name: category.name }
    end

    def serialize_product(product)
      {
        id: product.id,
        name: product.name,
        price: product.price.to_f,
        images_by_color: product.image_colors.map { |color, indices|
          { color: color, images: indices.map { |i| { url: url_for(product.images[i]) } } }
        },
        colors: product.colors,
        category_id: product.category.slug
      }
    end
  end
end
