Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    resources :categories, only: [:index, :show], param: :slug
    resources :products, only: [:index, :show]

    post "users/lookup", to: "users#lookup"
    resources :users, only: [:create]

    resource :cart, only: [:show] do
      post :add_item
      delete :clear
      patch "items/:id", to: "carts#update_item", as: :cart_item_update
      delete "items/:id", to: "carts#remove_item", as: :cart_item_remove
    end

    resources :addresses, only: [:index, :create, :update, :destroy]

    get "favorites", to: "favorites#index"
    post "favorites", to: "favorites#create"
    delete "favorites/:product_id", to: "favorites#destroy"
  end
end
