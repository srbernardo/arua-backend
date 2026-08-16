module Api
  module Admin
    class DashboardController < BaseController
      def index
        render json: {
          counts: {
            products: Product.count,
            categories: Category.count,
            orders: Order.count,
            users: User.count
          },
          revenue: {
            total: Order.sum(:total).to_f,
            pending: Order.where(status: "pending").sum(:total).to_f
          },
          recent_orders: recent_orders
        }
      end

      private

      def recent_orders
        Order.includes(:user).order(created_at: :desc).limit(5).map do |o|
          {
            id: o.id,
            order_number: o.order_number,
            status: o.status,
            total: o.total.to_f,
            user: { id: o.user.id, name: o.user.name },
            created_at: o.created_at
          }
        end
      end
    end
  end
end
