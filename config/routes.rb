Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      get "session", to: "sessions#show"
      post "session", to: "sessions#create"
      delete "session", to: "sessions#destroy"
      get "dashboard", to: "dashboard#show"
      get "reference", to: "reference#show"
      get "exports/compensation", to: "exports#show"
      resources :employees, only: [ :index, :show, :create, :update ] do
        resources :salary_records, only: [ :create ]
      end
    end
  end

  root "spa#index"
  get "*path", to: "spa#index", constraints: lambda { |request|
    request.get? && request.format.html? && !request.path.start_with?("/api", "/rails", "/vite", "/assets", "/up")
  }
end
