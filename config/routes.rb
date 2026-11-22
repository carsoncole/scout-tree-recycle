Rails.application.routes.draw do
  # Public pages
  root "public#index"
  get "about", to: "public#about"
  get "privacy", to: "public#privacy"
  get "credits", to: "public#credits"

  resources :thanks, only: [ :index ] do
    member do
      get :image
    end
  end

  resources :passwords, param: :token, only: [ :new, :create, :edit, :update ]
  resources :account_setups, param: :token, only: [ :edit, :update ]

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

  # Contacts
  resources :contacts, only: [] do
    member do
      get :unsubscribe
      post :unsubscribe
    end
  end

  # Admin pages
  namespace :admin do
    root to: "reservations#index"
    resource :session, only: [ :new, :create, :destroy ]
    resource :profile, only: [ :show, :update ]
    resources :reservations, except: [ :new, :create ] do
      member do
        post :geocode
        post :route
        patch :assign_route
        post :resend_email
      end
    end
    resources :settings, only: [ :index, :new, :create, :update ] do
      member do
        patch :toggle
        post :send_test_email
      end
    end
    get "settings/:section", to: "settings#show", as: :settings_section,
        constraints: { section: /event|organization|site_details|site_content|pickups|sms|email|donations|location_services|system/ }
    get "configuration", to: "configuration#index", as: :configuration
    scope path: "settings" do
      resources :drivers, except: [ :show ]
      resources :users, except: [ :show ] do
        member do
          patch :toggle
        end
      end
      resources :thanks, except: [ :show ]
      resources :routes do
        resources :points, only: [ :create, :destroy ]
        member do
          post :add_driver
          delete :remove_driver
        end
      end
      resources :zones
      resources :locations
    end
    resources :contacts, only: [ :show, :new, :create, :edit, :update, :destroy ] do
      member do
        delete :clear_marketing_email_1
        delete :clear_marketing_email_2
        post :send_marketing_email_1
        post :send_marketing_email_2
      end
      collection do
        delete :destroy_all
      end
    end
    resources :donations, only: [ :index, :show, :destroy ]
    resource :analytics, only: [ :show ], controller: "analytics"

    # Pickups (operational overview and driver backup report)
    resources :pickups, only: [ :index ]
    get "pickups/report", to: "pickups#report", as: :pickups_report

    # Mail archive. Manual sends and replies live here. Template mail stays on its mailers.
    namespace :mail, module: :mails do
      resources :received_emails, only: [ :index, :show, :update, :destroy ] do
        member do
          patch :read
        end
        resources :replies, only: [ :create ]
      end
      resources :outbound_emails, only: [ :index, :show, :new, :create, :update, :destroy ]
    end

    # SMS
    resources :sms, only: [ :index, :create ] do
      collection do
        post :mark_viewed
        delete :destroy
      end
    end
    get "sms/thread/:phone", to: "sms#show", as: :sms_thread

    # System logs
    scope path: "system" do
      delete "logs", to: "logs#destroy_all", as: :destroy_all_logs
      resources :logs, only: [ :index, :show, :destroy ]
    end

    # System data
    resource :data, only: [ :show ], controller: "data" do
      post :import
    end

    # Data backups and restores
    resource :backups, only: [ :create ], controller: "backups" do
      post :email
      post :schedule
      post :restore_settings
      post :restore_reservations
    end

    # Data management (delete all reservations/contacts, reset all data)
    resource :data_reset, only: [ :create ]

    # Close the current event and prepare contacts for the next one.
    resource :close_event, only: [ :show, :create ], controller: "operations", path: "close-event"



    # Marketing
    get "marketing/index"
    get "marketing/images", to: "marketing_images#index", as: :marketing_images
    post "send-marketing-email-1", to: "marketing#send_marketing_email_1", as: :send_marketing_email_1
    post "send-marketing-email-2", to: "marketing#send_marketing_email_2", as: :send_marketing_email_2
    post "marketing/send-test", to: "marketing#send_test", as: :send_marketing_email_test

    resources :marketing_email_templates, except: [ :show ] do
      member do
        get :preview
        post :send_test
        patch :publish
        patch :unpublish
        post :restore_default
      end

      collection do
        post :install_defaults
      end
    end

    resources :reservation_email_templates, only: [ :index, :edit, :update ] do
      member do
        get :preview
        post :send_test
        patch :publish
        patch :unpublish
        post :restore_default
      end

      collection do
        post :install_defaults
      end
    end

    mount MissionControl::Jobs::Engine, at: "/jobs"
  end

  # Pickup instructions (top-level aliases for the pickups portal)
  get "pickups/pickup_instructions", to: "pickups/drivers#pickup_instructions", as: :pickup_instructions
  get "pickups/instructions", to: "pickups/drivers#instructions", as: :instructions

  # Pickups namespace for drivers
  namespace :pickups do
    root to: "drivers#home"
    get "unauthorized", to: "drivers#unauthorized"
    resources :drivers, only: [ :index ]
    resources :zones, only: [ :index, :show ]
    resources :routes, only: [ :index, :show ] do
      member do
        post :favorite
        delete :unfavorite
      end
      resources :reservations, only: [ :show, :update ]
    end
    get "driver_pickup_lists", to: "drivers#driver_pickup_lists"
    get "pickup_instructions", to: "drivers#pickup_instructions"
    get "instructions", to: "drivers#instructions"
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

  # Blob URLs for database-backed Active Storage. The mail screens do not link here.
  mount ActiveStorageDB::Engine => "/active_storage_db"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
