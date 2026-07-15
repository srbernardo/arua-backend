module Api
  class ProductsController < ApplicationController
    def index
      products = Product.includes(:product_images, :category)

      if params[:category_id].present?
        products = products.joins(:category).where(categories: { slug: params[:category_id] })
      end

      if params[:q].present?
        products = products.where("products.name ILIKE ?", "%#{params[:q]}%")
      end

      products = case params[:sort]
      when "price_asc"  then products.order(price: :asc)
      when "price_desc" then products.order(price: :desc)
      when "name_asc"   then products.order(name: :asc)
      when "name_desc"  then products.order(name: :desc)
      else products.order(:name)
      end

      render json: products.map { |p| serialize_product(p) }
    end

    def show
      product = Product.includes(:product_images, :category).find(params[:id])
      render json: serialize_product(product)
    end

    private

    def serialize_product(product)
      {
        id: product.id,
        name: product.name,
        price: product.price.to_f,
        images: product.product_images.map(&:url),
        colors: product.colors
      }
    end
  end
end
