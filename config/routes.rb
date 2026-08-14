Rails.application.routes.draw do
  # Devise mapping for the Admin model. Routes are skipped because the API
  # exposes custom JSON endpoints under /api/admin; the helpers
  # (current_admin, sign_in, sign_out, ...) are still generated.
  devise_for :admins, skip: :all

  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    resources :categories, only: [:index, :show], param: :slug
    resources :products, only: [:index, :show]

    post "users/lookup", to: "users#lookup"
    resources :users, only: [:create]

    resource :cart, only: [:show] do
      post :add_item
      post :attach
      delete :clear
      patch "items/:id", to: "carts#update_item", as: :cart_item_update
      delete "items/:id", to: "carts#remove_item", as: :cart_item_remove
    end

    resources :addresses, only: [:index, :create, :update, :destroy]

    get "favorites", to: "favorites#index"
    post "favorites", to: "favorites#create"
    delete "favorites/:product_id", to: "favorites#destroy"

    resources :orders, only: [:create, :index, :show]

    namespace :admin do
      post "sign_in", to: "sessions#create"
      delete "sign_out", to: "sessions#destroy"
      get "me", to: "sessions#me"

      get "dashboard", to: "dashboard#index"

      resources :products, only: [:index, :show]
      resources :orders, only: [:index, :show]
      resources :categories, only: [:index, :create, :update, :destroy], param: :slug
      resources :users, only: [:index, :show]
    end
  end
end
