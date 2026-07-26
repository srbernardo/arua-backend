module Api
  class OrdersController < ApplicationController
    before_action :authenticate_user

    MAX_ORDERS_PER_HOUR = 5
    SHIPPING_COST = 7.99

    def create
      recent_orders = @user.orders.where("created_at > ?", 1.hour.ago).count
      if recent_orders >= MAX_ORDERS_PER_HOUR
        render json: { error: "Demasiados pedidos. Tente novamente mais tarde." }, status: :too_many_requests
        return
      end

      cart_items = CartItem.where(id: order_params[:item_ids]).includes(variant: :product)

      if cart_items.empty?
        render json: { error: "Nenhum item válido selecionado" }, status: :unprocessable_entity
        return
      end

      cart_items.each do |item|
        product = item.variant.product
        if product.nil?
          render json: { error: "Produto não encontrado para o item #{item.id}" }, status: :unprocessable_entity
          return
        end
      end

      order = nil

      ActiveRecord::Base.transaction do
        subtotal = 0
        order_items_data = []

        cart_items.each do |item|
          variant = item.variant
          product = variant.product
          quantity = item.quantity

          updated = Variant.where(id: variant.id)
                           .where("stock >= ?", quantity)
                           .update_all(["stock = stock - ?", quantity])

          if updated.zero?
            raise ActiveRecord::Rollback, "Stock insuficiente para #{product.name} (#{variant.size}/#{variant.color})"
          end

          unit_price = product.price
          subtotal += unit_price * quantity

          order_items_data << {
            variant_id: variant.id,
            product_id: product.id,
            quantity: quantity,
            unit_price: unit_price,
            created_at: Time.current,
            updated_at: Time.current
          }
        end

        total = subtotal + SHIPPING_COST

        order = @user.orders.create!(
          status: "pending",
          payment_method: order_params[:payment_method],
          address_street: order_params[:address][:street],
          address_neighborhood: order_params[:address][:neighborhood],
          address_city: order_params[:address][:city],
          address_state: order_params[:address][:state],
          address_zip: order_params[:address][:zip],
          subtotal: subtotal,
          shipping: SHIPPING_COST,
          total: total
        )

        order_items_data.each do |data|
          data[:order_id] = order.id
        end

        OrderItem.insert_all(order_items_data)
        CartItem.where(id: cart_items.map(&:id)).delete_all
      end

      if order.nil?
        render json: { error: "Erro ao processar pedido" }, status: :unprocessable_entity
        return
      end

      order.reload

      OrderConfirmationJob.perform_later(order.id)

      whatsapp_url = build_whatsapp_url(order)

      render json: serialize_order(order, whatsapp_url), status: :created
    end

    private

    def authenticate_user
      phone = request.headers["X-Phone"]
      @user = User.find_by_phone(phone) if phone
      render json: { error: "Utilizador não encontrado" }, status: :unauthorized unless @user
    end

    def order_params
      params.permit(
        :payment_method,
        :item_ids,
        address: [:street, :neighborhood, :city, :state, :zip]
      )
    end

    def build_whatsapp_url(order)
      store_phone = ENV.fetch("STORE_WHATSAPP_PHONE", "")
      return nil if store_phone.blank?

      items_text = order.order_items.includes(:product, :variant).map do |item|
        "#{item.quantity}x #{item.product.name} (#{item.variant.size}/#{item.variant.color}) - #{item.unit_price.to_f} €"
      end.join("%0A")

      message = "Pedido ##{order.order_number}%0A" \
                 "%0A" \
                 "#{items_text}%0A" \
                 "%0A" \
                 "Subtotal: #{order.subtotal} €%0A" \
                 "Frete: #{order.shipping} €%0A" \
                 "Total: #{order.total} €%0A" \
                 "%0A" \
                 "Pagamento: #{order.payment_method == 'mbway' ? 'MB Way' : 'Dinheiro'}%0A" \
                 "Morada: #{order.address_street}, #{order.address_city}, #{order.address_state}%0A" \
                 "Código Postal: #{order.address_zip}"

      "https://wa.me/#{store_phone}?text=#{message}"
    end

    def serialize_order(order, whatsapp_url)
      items = order.order_items.includes(:product, :variant).map do |item|
        {
          product_name: item.product.name,
          variant_size: item.variant.size,
          variant_color: item.variant.color,
          quantity: item.quantity,
          unit_price: item.unit_price.to_f
        }
      end

      {
        id: order.id,
        order_number: order.order_number,
        status: order.status,
        payment_method: order.payment_method,
        address: {
          street: order.address_street,
          neighborhood: order.address_neighborhood,
          city: order.address_city,
          state: order.address_state,
          zip: order.address_zip
        },
        subtotal: order.subtotal.to_f,
        shipping: order.shipping.to_f,
        total: order.total.to_f,
        items: items,
        whatsapp_url: whatsapp_url,
        created_at: order.created_at
      }
    end
  end
end
