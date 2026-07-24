module Api
  class AddressesController < ApplicationController
    before_action :authenticate_user

    def index
      render json: @user.addresses.ordered.map { |a| serialize_address(a) }
    end

    def create
      address = @user.addresses.build(address_params)
      address.make_default! if @user.addresses.none?

      if address.save
        render json: serialize_address(address), status: :created
      else
        render json: { errors: address.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      address = @user.addresses.find(params[:id])

      if params[:default] && address.update(default: true)
        @user.addresses.where.not(id: address.id).update_all(default: false)
      end

      if address.update(address_params)
        render json: serialize_address(address)
      else
        render json: { errors: address.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      @user.addresses.find(params[:id]).destroy!
      head :no_content
    end

    private

    def authenticate_user
      phone = auth_user_params[:phone].presence || request.headers["X-Phone"].presence
      @user = User.find_by_phone(phone) if phone
      render json: { error: "Utilizador não encontrado" }, status: :unauthorized unless @user
    end

    def address_params
      params.permit(:street, :neighborhood, :city, :state, :zip, :default)
    end

    def auth_user_params
      params.permit(:phone)
    end

    def serialize_address(address)
      {
        id: address.id,
        street: address.street,
        neighborhood: address.neighborhood,
        city: address.city,
        state: address.state,
        zip: address.zip,
        default: address.default
      }
    end
  end
end
