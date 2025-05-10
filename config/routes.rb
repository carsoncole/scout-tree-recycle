Rails.application.routes.draw do
  get "sms/reply"
  resources :passwords, param: :token
  # Public pages
  root "public#index"

  get "about", to: "public#about"
  get "privacy", to: "public#privacy"

  resources :reservations, only: [ :create, :update, :edit, :destroy ] do
    get "address_verification", to: "address_verification#address_verification", as: :address_verification
    patch "address_confirmation", to: "address_verification#address_confirmation", as: :address_confirmation
    get "confirmation", to: "reservations#confirmation", as: :confirmation
    resources :donations, only: [ :index, :new, :create ]
  end

  # Prior Reservations
  resources :prior_reservations, only: [] do
    member do
      get :unsubscribe
      delete :destroy
    end
  end

    # Incoming SMS
    post "sms/reply" => "sms#reply"

  # Admin pages
  namespace :admin do
    resource :session
    root to: "reservations#index"
    get "marketing/index"
    resources :reservations, only: [ :index, :show, :edit, :update ] do
      member do
        post :geocode
      end
    end
    resources :drivers
    resources :settings, only: [ :index, :update ] do
      member do
        patch :toggle
      end
    end
    resources :routes
    resources :zones
    delete "logs", to: "logs#destroy_all", as: :destroy_all_logs
    resources :logs, only: [ :index, :show, :destroy ]
    resources :users, except: [ :show ]
    resources :prior_reservations, only: [ :destroy ]
    resources :sms, only: [ :index, :create ] do
      collection do
        post :mark_viewed
        delete :destroy
      end
    end
    post "sms", to: "sms#create", as: :sms_index

    # Operations
    post "post-event-cleanup", to: "operations#post_event_cleanup"

    # Marketing
    post "send-marketing-email-1", to: "marketing#send_marketing_email_1", as: :send_marketing_email_1
    post "send-marketing-email-2", to: "marketing#send_marketing_email_2", as: :send_marketing_email_2

    mount MissionControl::Jobs::Engine, at: "/jobs"
  end

  # Pickups namespace for drivers
  namespace :pickups do
    root to: "drivers#index"
    get "unauthorized", to: "drivers#unauthorized"
    resources :drivers, only: [ :index ]
    get "driver_pickup_lists", to: "drivers#driver_pickup_lists"
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
