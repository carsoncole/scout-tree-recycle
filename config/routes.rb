Rails.application.routes.draw do
  # Public pages
  root "public#index"
  get "about", to: "public#about"
  get "privacy", to: "public#privacy"

  resources :passwords, param: :token, only: [ :new, :create, :edit, :update ]

  resources :reservations, only: [ :create, :update, :edit, :destroy ] do
    get "address_verification", to: "address_verification#address_verification", as: :address_verification
    get "confirmation", to: "reservations#confirmation", as: :confirmation

    # Donations
    resources :donations, only: [ :index, :new, :create ]
    post "cash-or-check" => "donations#cash_or_check", as: "cash_or_check"
    post "no-donation" => "donations#no_donation", as: "no_donation"
    get "donations/success" => "donations#success", as: "success"
  end

  # Donations
  get "/donation" => "donations#donation_without_reservation", as: "donation_without_reservation"
  get "/thank-you-for-your-donation" => "donations#success", as: "success"

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
    resource :session, only: [ :new, :create, :destroy ]
    resources :reservations, except: [ :new, :create ] do
      member do
        post :geocode
      end
    end
    resources :drivers, except: [ :show ]
    resources :settings, only: [ :index, :new, :create, :update ] do
      member do
        patch :toggle
      end
    end
    resources :routes do
      resources :points, only: [ :create, :destroy ]
      member do
        post :add_driver
        delete :remove_driver
      end
    end
    resources :zones, except: [ :show ]
    resources :users, except: [ :show ]
    resources :prior_reservations, only: [ :destroy ]
    resources :donations, only: [ :index, :show, :destroy ]

    # SMS
    resources :sms, only: [ :index, :create ] do
      collection do
        post :mark_viewed
        delete :destroy
      end
    end
    get "sms/thread/:phone", to: "sms#show", as: :sms_thread

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
    namespace :v1 do
      # Incoming Stripe transaction confirmation
      post "stripe-webhook", to: "donations#stripe_webhook"
      # Incoming SMS
      post "sms/reply", to: "sms#reply"
    end

    # Deprecated aliases kept while external webhook URLs migrate to /api/v1.
    post "stripe-webhook", to: "v1/donations#stripe_webhook"
    post "sms/reply", to: "v1/sms#reply"
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
