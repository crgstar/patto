Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    post '/signup', to: 'users#create'
    post '/login', to: 'sessions#create'
    delete '/logout', to: 'sessions#destroy'
    get '/current_user', to: 'current_user#show'

    # フィードソース管理（設定画面用）
    resources :feed_sources, only: [:index, :create, :update, :destroy] do
      member do
        post :refresh
      end
    end

    resources :stickies, only: [:index, :create, :update, :destroy] do
      collection do
        patch :reorder
      end
      resources :checklist_items, only: [:create, :update, :destroy] do
        collection do
          patch :reorder
        end
      end
      # FeedReader用
      resources :sticky_feed_sources, only: [:index, :create, :destroy] do
        collection do
          patch :reorder
        end
      end
    end
  end
end
