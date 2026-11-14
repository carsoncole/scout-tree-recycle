# OPTIMIZE: geocoding is working, need to clean up
module Geocodable
  extend ActiveSupport::Concern

  included do
    geocoded_by :address

    validates :street, :city, :state, :country, presence: true

    # DISABLED: geocoding and routing is handled by a job
    # geocoding and routing
    # before_validation :full_geocode!, if: ->(obj){ obj.address.present? && obj.street_changed? && !(obj.latitude_changed? && obj.longitude_changed?) }

    def address
      [ street, city, state, country ].compact.join(", ")
    end

    def short_address
      [ street, city, state ].compact.join(", ")
    end

    def coordinates
      if geocoded?
        [ latitude, longitude ]
      end
    end

    # def geocoded? (this is a method in geocoder)

    def full_geocode!
      if self.class == Reservation
        return false if self.is_manually_geocoded?
      end

      unless Setting.instance&.configure_location_service!
        Rails.logger.warn("Location services are not configured")
        return false
      end

      update_columns(was_automatically_geocoded: true)

      if Geocoder.config.lookup == :nominatum
        # Rails.error.handle do
        #   results = Geocoder.search(self.address)
        #   self.latitude = results.as_json[0]["data"]["lat"]
        #   self.longitude = results.as_json[0]["data"]["lon"]
        #   self.house_number = results.as_json[0]["data"]["address"]["house_number"]
        #   self.street_name = results.as_json[0]["data"]["address"]["road"]
        # end
        # geocode
        # self.was_geocoded = true
      elsif Geocoder.config.lookup == :amazon_location_service
        # multiple results (seems like 2) can be return, the second being a coordinate of just the street, not number
        # Rails.error.handle(context: { reservation_id: id, email: email }) do
        begin
          results = Geocoder.search(self.address)
          if results.count == 1
            geocode
            self.update_columns(latitude: self.latitude, longitude: self.longitude)
          elsif results.count == 2 && results.as_json[0]["place"]["address_number"].present?
            result = results.as_json[0]["place"]
            self.latitude = result["geometry"]["point"][1]
            self.longitude = result["geometry"]["point"][0]
            self.house_number = result["geometry"]["address_number"]
            self.street_name = result["street"]
            self.update_columns(latitude: self.latitude, longitude: self.longitude)
          end
        end
      end
      self.geocoded?
    end
  end
end
