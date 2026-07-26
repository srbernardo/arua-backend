module Api
  class FavoritesController < ApplicationController
    before_action :authenticate_user

    def index
      favorites = @user.favorites.includes(product: [:category, { images_attachments: :blob }]).order(created_at: :desc)

      render json: favorites.map { |f| serialize_favorite(f) }
    end

    def create
      favorite = @user.favorites.build(favorite_params)

      if favorite.save
        render json: serialize_favorite(favorite), status: :created
      else
        render json: { errors: favorite.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      favorite = @user.favorites.find_by!(product_id: params[:product_id])
      favorite.destroy!
      head :no_content
    end

    private

    def authenticate_user
      phone = request.headers["X-Phone"]
      @user = User.find_by_phone(phone) if phone
      render json: { error: "Utilizador não encontrado" }, status: :unauthorized unless @user
    end

    def favorite_params
      params.permit(:product_id)
    end

    def serialize_favorite(favorite)
      product = favorite.product
      category = product.category

      {
        id: favorite.id,
        product: {
          id: product.id,
          name: product.name,
          price: product.price.to_f,
          category: category.name,
          image_url: product.images.attached? ? url_for(product.images.first) : nil
        },
        created_at: favorite.created_at
      }
    end
  end
end
