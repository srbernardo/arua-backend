module Api
  class OrdersController < ApplicationController
    include Api::CartSerialization

    before_action :authenticate_user

    MAX_ORDERS_PER_HOUR = 5
    SHIPPING_COST = 7.99

    def index
      orders = @user.orders.includes(order_items: { product: { images_attachments: :blob }, variant: :product })
                    .order(created_at: :desc)

      render json: orders.map { |order| serialize_order_summary(order) }
    end

    def show
      order = @user.orders.includes(order_items: { product: { images_attachments: :blob }, variant: :product })
                   .find(params[:id])
      render json: serialize_order(order)
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Pedido não encontrado" }, status: :not_found
    end

    def create
      recent_orders = @user.orders.where("created_at > ?", 1.hour.ago).count
      if recent_orders >= MAX_ORDERS_PER_HOUR
        render json: { error: "Demasiados pedidos. Tente novamente mais tarde." }, status: :too_many_requests
        return
      end

      cart = find_session_cart
      cart_items = cart ? cart.cart_items.where(id: order_params[:item_ids]).includes(variant: :product) : []

      if cart_items.empty?
        render json: { error: "Nenhum item válido selecionado" }, status: :unprocessable_entity
        return
      end

      if cart_items.size != order_params[:item_ids].size
        render json: { error: "Alguns itens já não estão disponíveis." }, status: :unprocessable_entity
        return
      end

      invalid_items = cart_items.select { |item| item.variant.nil? || item.variant.product.nil? }
      unless invalid_items.empty?
        CartItem.where(id: invalid_items.map(&:id)).delete_all
        render json: {
          error: "Alguns produtos já não estão disponíveis e foram removidos do carrinho.",
          cart: serialize_cart(cart.reload)
        }, status: :unprocessable_entity
        return
      end

      unavailable = cart_items.select { |item| item.variant.stock < item.quantity }
      unless unavailable.empty?
        CartItem.where(id: unavailable.map(&:id)).delete_all
        names = unavailable.map { |item| "#{item.variant.product.name} (#{item.variant.size})" }
        message = if names.length == 1
                    "O item #{names.first} já não está disponível."
                  else
                    "Os itens #{names.join(', ')} já não estão disponíveis."
                  end
        render json: {
          error: message,
          cart: serialize_cart(cart.reload)
        }, status: :unprocessable_entity
        return
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

      render json: serialize_order(order).merge(cart: serialize_cart(cart.reload)), status: :created
    end

    private

    def authenticate_user
      phone = request.headers["X-Phone"]
      @user = User.find_by_phone(phone) if phone
      render json: { error: "Utilizador não encontrado" }, status: :unauthorized unless @user
    end

    def find_session_cart
      token = request.headers["X-Cart-Token"].presence
      Cart.find_by(session_id: token)
    end

    def order_params
      params.permit(
        :payment_method,
        item_ids: [],
        address: [:street, :neighborhood, :city, :state, :zip]
      )
    end

    def build_whatsapp_url(order)
      store_phone = ENV.fetch("STORE_WHATSAPP_PHONE", "")
      return nil if store_phone.blank?

      separator = "________________________"

      items_text = order.order_items.includes(:product, :variant).map do |item|
        "#{item.quantity}x - *#{item.product.name}* (#{item.variant.size}/#{item.variant.color})\n" \
        "#{item.unit_price.to_f} €"
      end.join("\n\n#{separator}\n\n")

      message = "*ARUA - Loja Online*\n" \
                 "*Pedido ##{order.order_number}*\n" \
                 "\n" \
                 "*Meu nome é #{order.user.name}, contato: #{order.user.phone}*\n" \
                 "#{separator}\n" \
                 "\n" \
                 "*Itens do Pedido:*\n" \
                 "#{items_text}\n" \
                 "\n" \
                 "#{separator}\n" \
                 "\n" \
                 "*Subtotal:* #{order.subtotal} €\n" \
                 "*Entrega:* #{order.shipping} €\n" \
                 "*Total:* #{order.total} €\n" \
                 "\n" \
                 "#{separator}\n" \
                 "\n" \
                 "*Pagamento em:* #{order.payment_method == 'mbway' ? 'MB Way' : 'Dinheiro'}\n" \
                 "\n" \
                 "*Morada de Entrega*\n" \
                 "#{order.address_street}\n" \
                 "#{order.address_neighborhood}\n" \
                 "#{order.address_city}, #{order.address_state}, #{order.address_zip}"

      "https://wa.me/#{store_phone}?text=#{URI.encode_www_form_component(message)}"
    end

    def serialize_order(order)
      items = order.order_items.includes(:product, :variant).map do |item|
        {
          id: item.id,
          product_id: item.product.id,
          product_name: item.product.name,
          image_url: item.product.images.attached? ? url_for(item.product.images.first) : nil,
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
        observation: order.observation,
        whatsapp_url: build_whatsapp_url(order),
        created_at: order.created_at
      }
    end

    def serialize_order_summary(order)
      first_item = order.order_items.first
      first_product = first_item&.product

      {
        id: order.id,
        order_number: order.order_number,
        status: order.status,
        total: order.total.to_f,
        created_at: order.created_at,
        item_count: order.order_items.sum(:quantity),
        image_url: first_product&.images&.attached? ? url_for(first_product.images.first) : nil
      }
    end
  end
end
