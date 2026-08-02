module Api
  module CartSerialization
    private

    def serialize_cart(cart = @cart)
      items = cart.cart_items.includes(variant: { product: :category }).map do |item|
        product = item.variant.product
        next nil if product.nil?

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
      end.compact

      {
        cart_token: cart.session_id,
        items: items,
        total_items: items.sum { |i| i[:quantity] },
        total_price: items.sum { |i| i[:product][:price] * i[:quantity] }.round(2)
      }
    end
  end
end
