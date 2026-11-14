ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    include ActiveJob::TestHelper

    # Run tests in parallel with specified workers
    # parallelize(workers: :number_of_processors)

    fixtures :all

    # sign_in for system tests
    def sign_in_as(user, fixture = false)
      visit new_admin_session_url
      fill_in "Email", with: user.email
      fill_in "Password", with: (fixture ? "password123456789" : user.password)
      click_button "Sign in"
      sleep 1
    end

    # sign_in for controller tests
    def sign_in(user = users(:admin))
      session = user.sessions.create!
      Current.session = session
      request = ActionDispatch::Request.new(Rails.application.env_config)
      cookies = request.cookie_jar
      cookies.signed[:session_id] = { value: session.id, httponly: true, same_site: :lax }
    end

    # making a reservation
    def make_system_reservation(email = Faker::Internet.email)
      visit root_url
      fill_in "Name", with: Faker::Name.name
      fill_in "Street", with: Faker::Address.street_address
      fill_in "Email", with: email
      fill_in "Mobile", with: Faker::PhoneNumber.phone_number
      click_button "Create Reservation"
    end
  end
end
