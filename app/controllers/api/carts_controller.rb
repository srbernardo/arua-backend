module Api
  class CartsController < ApplicationController
    before_action :find_or_create_cart

    def show
      render json: serialize_cart
    end

    def add_item
      variant = Variant.find(params[:variant_id])
      quantity = [params.fetch(:quantity, 1).to_i, 1].max

      if variant.stock < quantity
        render json: { errors: ["Estoque insuficiente"] }, status: :unprocessable_entity
        return
      end

      item = @cart.cart_items.find_or_initialize_by(variant: variant)
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
      elsif quantity > item.variant.stock
        render json: { errors: ["Estoque insuficiente"] }, status: :unprocessable_entity
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

    def attach
      user = User.find_by_phone(request.headers["X-Phone"])
      return render json: { error: "Utilizador não encontrado" }, status: :unauthorized unless user

      if @cart.user_id == user.id
        render json: serialize_cart
        return
      end

      ActiveRecord::Base.transaction do
        user_cart = Cart.find_by(user_id: user.id)

        if user_cart
          merge_items(user_cart)
          user_cart.destroy!
        end

        @cart.update!(user_id: user.id)
      end

      render json: serialize_cart
    end

    private

    def merge_items(user_cart)
      user_cart.cart_items.includes(:variant).find_each do |existing|
        variant = existing.variant
        next if variant.stock <= 0

        item = @cart.cart_items.find_or_initialize_by(variant: variant)
        quantity = item.new_record? ? existing.quantity : item.quantity + existing.quantity
        item.quantity = [quantity, variant.stock].min
        item.save!
      end
    end

    def find_or_create_cart
      token = request.headers["X-Cart-Token"].presence
      token ||= SecureRandom.uuid

      @cart = Cart.find_or_create_by!(session_id: token)
    end

    def serialize_cart
      items = @cart.cart_items.includes(variant: { product: :category }).map do |item|
        product = item.variant.product
        {
          id: item.id,
          product: {
            id: product.id,
            name: product.name,
            price: product.price.to_f,
            sizes: product.sizes,
            images_by_color: product.image_colors.map { |color, indices|
              { color: color, images: indices.map { |i| { url: url_for(product.images[i]) } } }
            },
            colors: product.colors,
            category_id: product.category.slug
          },
          variant: {
            size: item.variant.size,
            color: item.variant.color,
            sku: item.variant.sku
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
