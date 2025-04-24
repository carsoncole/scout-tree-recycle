Rails.application.routes.draw do

  # Public pages
  root "public#index"

  get "about", to: "public#about"

  resources :reservations, only: [:create, :update, :edit, :destroy] do
    get "address_verification", as: :address_verification
    patch "address_confirmation", as: :address_confirmation
    get "confirmation", as: :confirmation
    resources :donations, only: [:new, :create]
  end

  # Admin pages
  namespace :admin do
    resources :reservations, except: [:create, :new]
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
