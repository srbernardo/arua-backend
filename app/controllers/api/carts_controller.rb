module Api
  class CartsController < ApplicationController
    before_action :find_or_create_cart

    def show
      render json: serialize_cart
    end

    def add_item
      product = Product.find(params[:product_id])
      quantity = [params.fetch(:quantity, 1).to_i, 1].max

      item = @cart.cart_items.find_or_initialize_by(product: product)
      item.quantity = item.new_record? ? quantity : item.quantity + quantity

      if item.save
        render json: serialize_cart, status: :created
      else
        render json: { errors: item.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update_item
      item = @cart.cart_items.find(params[:id])
      quantity = params.fetch(:quantity, 1).to_i

      if quantity <= 0
        item.destroy
      elsif item.update(quantity: quantity)
        render json: serialize_cart
      else
        render json: { errors: item.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def remove_item
      item = @cart.cart_items.find(params[:id])
      item.destroy
      render json: serialize_cart
    end

    def clear
      @cart.cart_items.destroy_all
      render json: serialize_cart
    end

    private

    def find_or_create_cart
      token = request.headers["X-Cart-Token"].presence
      token ||= SecureRandom.uuid

      @cart = Cart.find_or_create_by!(session_id: token)
    end

    def serialize_cart
      items = @cart.cart_items.includes(:product).map do |item|
        product = item.product
        {
          id: item.id,
          product: {
            id: product.id,
            name: product.name,
            price: product.price.to_f,
            images: product.product_images.map(&:url),
            colors: product.colors
          },
          quantity: item.quantity
        }
      end

      {
        cart_token: @cart.session_id,
        items: items,
        total_items: items.sum { |i| i[:quantity] },
        total_price: items.sum { |i| i[:product][:price] * i[:quantity] }.round(2)
      }
    end
  end
end
