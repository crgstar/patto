Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    post '/signup', to: 'users#create'
    post '/login', to: 'sessions#create'
    delete '/logout', to: 'sessions#destroy'
    get '/current_user', to: 'current_user#show'

    resources :stickies, only: [:index, :create, :update, :destroy] do
      collection do
        patch :reorder
      end
      resources :checklist_items, only: [:create, :update, :destroy] do
        collection do
          patch :reorder
        end
      end
    end
  end
end
