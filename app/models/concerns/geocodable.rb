module Geocodable
  extend ActiveSupport::Concern

  included do
    geocoded_by :address

    validates :street, :city, :state, :country, presence: true

    # Geocoding and routing run in RouteReservationJob/RouteReservationsJob,
    # not in callbacks.

    def address
      [ street, city, state, country ].compact.join(", ")
    end

    def short_address
      [ street, city, state ].compact.join(", ")
    end

    def coordinates
      [ latitude, longitude ] if geocoded?
    end

    def preferred_geocode_result(results)
      Array(results).compact.select { |result| result.coordinates.present? }.max_by do |result|
        place = result.instance_variable_get(:@place)
        place.respond_to?(:address_number) && place.address_number.present? ? 1 : 0
      end
    end

    def full_geocode!
      return false if self.class == Reservation && is_manually_geocoded?

      unless Setting.instance&.configure_location_service!
        Rails.logger.warn("Location services are not configured")
        return false
      end

      update_columns(was_automatically_geocoded: true)

      # Amazon Location Service can return the street and a second match with
      # the house number. Prefer the more precise match. Coordinates come from
      # the Geocoder result, which treats the place point as [longitude, latitude].
      results = Geocoder.search(address, Setting.instance.location_search_options)
      result = preferred_geocode_result(results)
      return false unless result&.coordinates

      self.latitude, self.longitude = result.coordinates
      update_columns(latitude: latitude, longitude: longitude)

      geocoded?
    rescue Aws::LocationService::Errors::ServiceError => error
      Rails.logger.warn("Location service geocoding failed: #{error.class}: #{error.message}")
      false
    end
  end
end
