Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  # Public pages
  root "public#index"

  get "about", to: "public#about"

  resources :reservations, only: [:create, :update, :edit, :destroy] do
    get "address_verification", as: :address_verification
    patch "address_confirmation", as: :address_confirmation
    get "confirmation", as: :confirmation
    resources :donations, only: [:new, :create]
  end

  # Prior Reservations
  resources :prior_reservations, only: [] do
    member do
      get :unsubscribe
      delete :destroy
    end
  end

  # Admin pages
  namespace :admin do
    root to: "reservations#index"
    get "marketing/index"
    resources :reservations, only: [:index, :show, :edit, :update]
    resources :drivers
    resources :settings, only: [:index, :update] do
      member do
        patch :toggle
      end
    end
    resources :routes
    resources :zones
    delete "logs", to: "logs#destroy"
    resources :logs, only: [:index]
    resources :users

    # Operations
    post 'post-event-cleanup', to: 'operations#post_event_cleanup'

    # Marketing
    post 'send-marketing-email-1', to: 'marketing#send_marketing_email_1', as: :send_marketing_email_1
    post 'send-marketing-email-2', to: 'marketing#send_marketing_email_2', as: :send_marketing_email_2
  
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
