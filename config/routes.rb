Rails.application.routes.draw do
  # community_bookshelf's /api/v1 contract (its doc/openapi.yaml), shared with bookshelf-spa (#84).
  namespace :api do
    namespace :v1 do
      resource :session, only: [:show, :create, :destroy]
      resources :books, only: [:index, :show, :create, :update, :destroy]
      resources :readings, only: [:index, :show, :create, :update, :destroy]
      resources :tags, only: [:index]
      resource :book_search, only: [:show]

      namespace :admin do
        resource :dashboard, only: [:show]
        resources :users, only: [:index, :update]
        resources :readings, only: [:index]
      end
    end
  end

  # Not in the contract yet, so these keep their old paths until their community_bookshelf#219 slices.
  resources :books, only: [] do
    member { get :similar }
    collection { get :recommended }
  end
  resources :users, controller: "clearance/users", only: [:create]
  resource :account, only: [:show, :update, :destroy]

  get "up", to: "rails/health#show", as: :rails_health_check
end
