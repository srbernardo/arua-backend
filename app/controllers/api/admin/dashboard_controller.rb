module Api
  module Admin
    class DashboardController < BaseController
      def index
        render json: {
          counts: {
            products: Product.count,
            categories: Category.count,
            orders: Order.count,
            pending_orders: Order.where(status: "pending").count,
            users: User.count,
            low_stock_variants: low_stock_variants_count
          },
          revenue: {
            total: Order.sum(:total).to_f,
            pending: Order.where(status: "pending").sum(:total).to_f
          },
          low_stock: low_stock_products,
          recent_orders: recent_orders
        }
      end

      private

      def low_stock_threshold
        threshold = params[:low_stock_threshold].to_i
        threshold.positive? ? threshold : 5
      end

      def low_stock_variants_count
        Variant.where("stock <= ?", low_stock_threshold).count
      end

      def low_stock_products
        Variant.joins(:product)
               .where("variants.stock <= ?", low_stock_threshold)
               .group("products.id, products.name")
               .select("products.id AS product_id, products.name AS product_name, MIN(variants.stock) AS min_stock")
               .order("min_stock ASC")
               .limit(5)
               .map { |row| { product_id: row.product_id, name: row.product_name, min_stock: row.min_stock } }
      end

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
