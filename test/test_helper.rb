ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    fixtures :all

    def sign_in_as(user,fixture=false)
      visit new_admin_session_url
      fill_in "Email", with: user.email
      fill_in "Password", with: (fixture ? "password123456789" : user.password)
      click_button "Sign in"
      sleep 1
    end
  end
end
