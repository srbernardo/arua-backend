module Api
  class UsersController < ApplicationController
    def lookup
      user = User.find_by_phone(user_params[:phone])

      if user
        render json: { exists: true, user: { name: user.name, phone: user.phone } }
      else
        render json: { exists: false }
      end
    end

    def create
      user = User.find_by_phone(user_params[:phone])

      if user
        render json: { user: { name: user.name, phone: user.phone } }
      else
        user = User.new(user_params)
        if user.save
          render json: { user: { name: user.name, phone: user.phone } }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end

    private

    def user_params
      params.require(:user).permit(:name, :phone)
    end
  end
end
