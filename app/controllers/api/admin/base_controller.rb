module Api
  module Admin
    # Base controller for all authenticated admin endpoints.
    # Every action here requires a valid admin session cookie.
    class BaseController < ApplicationController
      protect_from_forgery with: :exception, unless: -> { request.get? }
      before_action :authenticate_admin!
      before_action :set_csrf_cookie

      private

      def authenticate_admin!
        return if current_admin

        render json: {
          error: "Não autenticado",
          csrf_token: form_authenticity_token
        }, status: :unauthorized
      end

      def serialize_admin(admin)
        { id: admin.id, email: admin.email, created_at: admin.created_at }
      end
    end
  end
end
