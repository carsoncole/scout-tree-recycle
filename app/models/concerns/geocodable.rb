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
      @geocode_failure_message = nil
      return fail_geocode("This address is manually geocoded.", logged: true) if self.class == Reservation && is_manually_geocoded?

      unless Setting.instance&.prepare_location_search!
        return fail_geocode("Location services are not configured.")
      end

      update_columns(was_automatically_geocoded: true)

      # Amazon Location Service can return the street and a second match with
      # the house number. Prefer the more precise match. Coordinates come from
      # the Geocoder result, which treats the place point as [longitude, latitude].
      # A blank place index raises ArgumentError in the AWS SDK before the
      # request is sent. ServiceError is the HTTP error response.
      results = Geocoder.search(address, Setting.instance.location_search_options)
      result = preferred_geocode_result(results)
      return fail_geocode("Amazon Location Service did not return coordinates for this address.") unless result&.coordinates

      self.latitude, self.longitude = result.coordinates
      update_columns(latitude: latitude, longitude: longitude)

      geocoded?
    rescue Aws::LocationService::Errors::ServiceError, ArgumentError => error
      log_location_service_error(error)
      fail_geocode("Geocoding failed: #{error.message}", logged: true)
    end
  end

  attr_reader :geocode_failure_message

  private

  def fail_geocode(message, logged: false)
    @geocode_failure_message = message
    log_geocode_failure(message) unless logged
    false
  end

  def log_geocode_failure(message)
    Rails.logger.warn(message)
    attributes = {
      log_type: "error",
      severity: "error",
      handled: true,
      error_type: "Geocoding",
      message: message,
      context: {
        address: address,
        region: Setting.instance&.aws_region,
        index_name: Setting.instance&.aws_location_index_name
      }.compact
    }
    attributes[:reservation_id] = id if is_a?(Reservation) && persisted?
    Log.create(attributes)
  rescue StandardError => logging_error
    Rails.logger.error("Geocoding failure could not be logged: #{logging_error.class}: #{logging_error.message}")
  end

  # Amazon's error response is the useful part of a failed geocode. Store it
  # on an Error log so an admin can see the status, request id, and body
  # without reading the server log. A logging failure must not change the
  # geocode result.
  def log_location_service_error(error)
    Rails.logger.warn("Location service geocoding failed: #{error.class}: #{error.message}")

    response = error.context.http_response if error.respond_to?(:context) && error.context.respond_to?(:http_response)
    headers = response&.headers
    attributes = {
      log_type: "error",
      severity: "error",
      handled: true,
      error_type: error.class.name,
      message: location_error_message(error, response),
      backtrace: Array(error.backtrace).join("\n").presence,
      context: {
        address: address,
        code: (error.code if error.respond_to?(:code)),
        status: response&.status_code,
        request_id: headers&.[]("x-amzn-requestid"),
        error_type: headers&.[]("x-amzn-errortype"),
        response_body: location_response_body(response),
        region: Setting.instance&.aws_region,
        index_name: Setting.instance&.aws_location_index_name
      }.compact
    }
    attributes[:reservation_id] = id if is_a?(Reservation) && persisted?

    Log.create(attributes)
  rescue StandardError => logging_error
    Rails.logger.error("Location service error could not be logged: #{logging_error.class}: #{logging_error.message}")
  end

  def location_error_message(error, response)
    parts = [ error.message.to_s.strip ]
    body = location_response_body(response)
    parts << body if body.present? && parts.none? { |part| part.include?(body) }
    parts.compact_blank.join("\n")
  end

  def location_response_body(response)
    body = response&.body_contents
    return if body.blank?

    body.to_s.truncate(5_000)
  rescue StandardError
    nil
  end
end
