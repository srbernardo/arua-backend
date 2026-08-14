module Api
  module Admin
    class SessionsController < ApplicationController
      protect_from_forgery with: :exception, unless: -> { request.get? }
      before_action :set_csrf_cookie

      # POST /api/admin/sign_in
      # Authenticates an admin with email + password and establishes a
      # session. The browser stores the HttpOnly session cookie and sends
      # it automatically on the next requests. No JWT, no localStorage.
      def create
        email = session_params[:email].to_s.strip.downcase
        password = session_params[:password].to_s

        admin = ::Admin.find_by(email: email)

        if admin && admin.valid_password?(password)
          sign_in(:admin, admin)
          render json: { admin: serialize_admin(admin), csrf_token: form_authenticity_token }
        else
          render json: {
            error: "Email ou senha inválidos",
            csrf_token: form_authenticity_token
          }, status: :unauthorized
        end
      end

      # DELETE /api/admin/sign_out
      # Destroys the current admin session.
      def destroy
        sign_out(:admin) if current_admin
        render json: { signed_out: true, csrf_token: form_authenticity_token }
      end

      # GET /api/admin/me
      # Returns the authenticated admin, or 401 when there is no valid session.
      def me
        if current_admin
          render json: { admin: serialize_admin(current_admin), csrf_token: form_authenticity_token }
        else
          render json: {
            error: "Não autenticado",
            csrf_token: form_authenticity_token
          }, status: :unauthorized
        end
      end

      private

      def serialize_admin(admin)
        { id: admin.id, email: admin.email, created_at: admin.created_at }
      end

      def session_params
        params.require(:admin).permit(:email, :password)
      end
    end
  end
end
