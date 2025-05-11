Rails.application.routes.draw do
  
  # Public pages
  root "public#index"
  get "about", to: "public#about"
  get "privacy", to: "public#privacy"

  get "sms/reply"
  resources :passwords, param: :token

  resources :reservations, only: [ :create, :update, :edit, :destroy ] do
    get "address_verification", to: "address_verification#address_verification", as: :address_verification
    # patch "address_confirmation", to: "address_verification#address_confirmation", as: :address_confirmation
    get "confirmation", to: "reservations#confirmation", as: :confirmation
    
    # Donations
    resources :donations, only: [ :index, :new, :create ]
    post 'cash-or-check' => 'donations#cash_or_check', as: 'cash_or_check'
    post 'no-donation' => 'donations#no_donation', as: 'no_donation'
    get 'donations/success' => 'donations#success', as: 'success'
    get 'donations/cancel' => 'donations#cancel', as: 'cancel'
    get 'confirmed' => 'reservations#confirmed', as: 'confirmed'
  end

  # Donations
  get '/donation' => 'donations#donation_without_reservation', as: 'donation_without_reservation'
  get '/thank-you-for-your-donation' => 'donations#success', as: 'success'

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
    resource :session
    resources :reservations, except: [ :new, :create ] do
      member do
        post :geocode
      end
    end
    resources :drivers, except: [ :show ]
    resources :settings, only: [ :index, :update ] do
      member do
        patch :toggle
      end
    end
    resources :routes do
      resources :points, only: [:create, :destroy]
      member do
        post :add_driver
        delete :remove_driver
      end
    end
    resources :zones
    resources :users, except: [ :show ]
    resources :prior_reservations, only: [ :destroy ]
    resources :donations, only: [:index, :show, :destroy]

    # SMS
    resources :sms, only: [:index, :create] do
      collection do
        post :mark_viewed
        delete :destroy
      end
    end
    post "sms", to: "sms#create", as: :sms_index

    # Logs
    delete "logs", to: "logs#destroy_all", as: :destroy_all_logs
    resources :logs, only: [ :index, :show, :destroy ]

    # Operations
    post "post-event-cleanup", to: "operations#post_event_cleanup"

    # Marketing
    get "marketing/index"
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

  # API for Stripe and Twilio webhooks
  namespace :api do
    # Incoming Stripe transaction confirmation
    post 'stripe-webhook' => "donations#stripe_webhook"
    # Incoming SMS
    post "sms/reply" => "sms#reply"
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
