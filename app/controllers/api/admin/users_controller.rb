module Api
  module Admin
    class UsersController < BaseController
      def index
        users = User.left_joins(:orders)
                    .select("users.*, COUNT(orders.id) AS orders_count, COALESCE(SUM(orders.total), 0) AS total_spent")
                    .group("users.id")
                    .order("users.created_at DESC")

        if params[:q].present?
          q = "%#{params[:q]}%"
          users = users.where("users.name ILIKE ? OR users.phone ILIKE ?", q, q)
        end

        page, meta = paginate(users)

        render json: {
          data: page.map { |u| serialize_user(u) },
          meta: meta
        }
      end

      def show
        user = User.left_joins(:orders)
                   .select("users.*, COUNT(orders.id) AS orders_count, COALESCE(SUM(orders.total), 0) AS total_spent")
                   .group("users.id")
                   .find(params[:id])
        render json: serialize_user(user)
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Utilizador não encontrado" }, status: :not_found
      end

      private

      def serialize_user(user)
        {
          id: user.id,
          name: user.name,
          phone: user.phone,
          orders_count: user.orders_count.to_i,
          total_spent: user.total_spent.to_f,
          created_at: user.created_at
        }
      end
    end
  end
end
