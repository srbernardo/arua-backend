module Api
  module Admin
    class OrdersController < BaseController
      STATUS_FILTERS = %w[pending confirmed shipped delivered cancelled].freeze

      def index
        orders = Order.includes(order_items: :product).order(created_at: :desc)

        if params[:status].present? && STATUS_FILTERS.include?(params[:status])
          orders = orders.where(status: params[:status])
        end

        render json: orders.map { |o| serialize_order_summary(o) }
      end

      def show
        order = Order.includes(order_items: { product: { images_attachments: :blob }, variant: :product })
                     .find(params[:id])
        render json: serialize_order(order)
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Pedido não encontrado" }, status: :not_found
      end

      private

      def serialize_order_summary(order)
        first_product = order.order_items.first&.product

        {
          id: order.id,
          order_number: order.order_number,
          status: order.status,
          payment_method: order.payment_method,
          total: order.total.to_f,
          item_count: order.order_items.sum(:quantity),
          user: { id: order.user_id, name: order.user.name, phone: order.user.phone },
          image_url: first_product&.images&.attached? ? url_for(first_product.images.first) : nil,
          created_at: order.created_at
        }
      end

      def serialize_order(order)
        items = order.order_items.map do |item|
          {
            id: item.id,
            product_id: item.product_id,
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
          user: { id: order.user.id, name: order.user.name, phone: order.user.phone },
          created_at: order.created_at
        }
      end
    end
  end
end
