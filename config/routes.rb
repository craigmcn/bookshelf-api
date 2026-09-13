Rails.application.routes.draw do
  resources :readings, only: [:index, :show, :create, :update, :destroy]
  resources :books, only: [:index, :show, :create, :update, :destroy] do
    member { get :similar }
    collection { get :recommended }
  end
  resources :tags, only: [:index]
  get "book_search", to: "book_search#index"

  get "up", to: "rails/health#show", as: :rails_health_check

  resource :session, controller: "sessions", only: [:show, :create, :destroy]
  resources :users, controller: "clearance/users", only: [:create]
  resource :account, only: [:show, :update, :destroy]

  namespace :admin do
    root "dashboard#index"
    resources :users, only: [:index, :update]
    resources :readings, only: [:index]
  end
end
