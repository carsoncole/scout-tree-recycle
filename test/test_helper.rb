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

      # Build a throwaway request env so the signed cookie jar is not stored in
      # Rails.application.env_config, which is merged into every test request.
      request = ActionDispatch::Request.new(Rails.application.env_config.dup)
      request.cookie_jar.signed[:session_id] = { value: session.id, httponly: true, same_site: :lax }

      cookies[:session_id] = request.cookie_jar[:session_id]
    end

    # Completes the donation step and waits for the confirmation page to load.
    def complete_donation(option = "Donate at Pickup")
      click_button option
      assert_current_path %r{\A/reservations/[^/]+/confirmation\z}
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

    # Stubs the external geocoding lookup so tests do not depend on AWS.
    def with_stubbed_geocoding(latitude: 40.7128, longitude: -74.0060)
      result = Struct.new(:latitude, :longitude) do
        def coordinates
          [ latitude, longitude ]
        end
      end.new(latitude, longitude)

      original = Geocoder.method(:search)
      Geocoder.define_singleton_method(:search) { |*_args, **_kwargs| [ result ] }
      yield
    ensure
      Geocoder.define_singleton_method(:search, original) if original
    end

    def configure_location_service!
      Setting.instance.update(
        location_provider: "places_v1",
        aws_access_key_id: "AKIATEST",
        aws_secret_access_key: "secret",
        aws_region: "us-west-2",
        aws_location_index_name: "tree_recycle"
      )
    end

    def configure_places_v2!
      Setting.instance.update!(
        location_provider: "places_v2",
        aws_location_api_key: "v1.public.test",
        aws_region: "us-west-2"
      )
    end

    # Address verification uses the same master switch as routing.
    def configure_address_verification!
      configure_places_v2!
      Setting.instance.update!(is_routing_enabled: true)
    end

    def with_stubbed_location_search(results)
      search = Object.new
      search.define_singleton_method(:geocode) { |_address| results }

      original = LocationSearch.method(:new)
      LocationSearch.define_singleton_method(:new) { |*_args, **_kwargs| search }
      yield
    ensure
      LocationSearch.define_singleton_method(:new, original) if original
    end

    def with_stubbed_location_search_error(error)
      search = Object.new
      search.define_singleton_method(:geocode) { |_address| raise error }

      original = LocationSearch.method(:new)
      LocationSearch.define_singleton_method(:new) { |*_args, **_kwargs| search }
      yield
    ensure
      LocationSearch.define_singleton_method(:new, original) if original
    end

    def with_stubbed_address_suggestions(suggestions)
      search = Object.new
      search.define_singleton_method(:autocomplete) { |_query| suggestions }

      original = LocationSearch.method(:new)
      LocationSearch.define_singleton_method(:new) { |*_args, **_kwargs| search }
      yield
    ensure
      LocationSearch.define_singleton_method(:new, original) if original
    end

    def with_stubbed_address_suggestions_error(error)
      search = Object.new
      search.define_singleton_method(:autocomplete) { |_query| raise error }

      original = LocationSearch.method(:new)
      LocationSearch.define_singleton_method(:new) { |*_args, **_kwargs| search }
      yield
    ensure
      LocationSearch.define_singleton_method(:new, original) if original
    end

    def verified_address_result(overrides = {})
      LocationSearch::Result.new(
        latitude: 40.7128,
        longitude: -74.0060,
        address_number: "123",
        street: "Main Street",
        locality: "New York",
        region: "New York",
        region_code: "NY",
        region_name: "New York",
        postal_code: "10001",
        country: "United States",
        country_code: "US",
        label: "123 Main Street, New York, NY 10001, United States",
        place_type: "PointAddress",
        match_score: 0.98,
        place_id: "place-123"
      ).tap { |result| overrides.each { |key, value| result[key] = value } }
    end

    def configure_email!(enabled: true)
      Setting.instance.update!(
        is_emailing_enabled: enabled,
        email_from_address: "example@example.com",
        smtp_address: "smtp.example.com",
        smtp_port: 587
      )
    end

    # email_configured? stays true, but ApplicationMailer must not switch the
    # process to SMTP while a mail archive test delivers a message.
    def with_test_delivery
      original = ApplicationMailer.instance_method(:apply_email_settings)
      ApplicationMailer.define_method(:apply_email_settings) do
        original.bind_call(self)
        ActionMailer::Base.delivery_method = :test
      end
      yield
    ensure
      ApplicationMailer.define_method(:apply_email_settings, original) if original
      ActionMailer::Base.delivery_method = :test
    end
  end
end
