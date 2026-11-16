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

    def full_geocode!
      return false if self.class == Reservation && is_manually_geocoded?

      unless Setting.instance&.configure_location_service!
        Rails.logger.warn("Location services are not configured")
        return false
      end

      update_columns(was_automatically_geocoded: true)

      # Amazon Location Service can return two matches: the first with a house
      # number and a second for just the street. Prefer the more precise match.
      results = Geocoder.search(address)
      if results.count == 1
        geocode
        update_columns(latitude: latitude, longitude: longitude)
      elsif results.count == 2 && results.as_json[0]["place"]["address_number"].present?
        result = results.as_json[0]["place"]
        self.latitude = result["geometry"]["point"][1]
        self.longitude = result["geometry"]["point"][0]
        self.house_number = result["geometry"]["address_number"]
        self.street_name = result["street"]
        update_columns(latitude: latitude, longitude: longitude)
      end

      geocoded?
    end
  end
end
