require "json"
require "net/http"
require "openssl"
require "uri"

# Client for the Amazon Location Service Places v2 Geocode and Autocomplete
# APIs.
#
# Geocode results are stored on reservations, so those requests use
# IntendedUse=Storage. Autocomplete suggestions are ephemeral and use
# IntendedUse=SingleUse.
class LocationSearch
  BASE_ENDPOINT = "https://places.geo.%s.amazonaws.com/v2"
  INTENDED_USE = "Storage"
  SUGGESTION_INTENDED_USE = "SingleUse"
  DEFAULT_MAX_RESULTS = 5
  OPEN_TIMEOUT = 5
  READ_TIMEOUT = 10

  class Error < StandardError
    attr_reader :status, :code, :request_id, :body

    def initialize(message, status: nil, code: nil, request_id: nil, body: nil)
      @status = status
      @code = code
      @request_id = request_id
      @body = body
      super(message)
    end
  end

  Result = Struct.new(
    :latitude,
    :longitude,
    :address_number,
    :street,
    :locality,
    :region,
    :region_code,
    :region_name,
    :postal_code,
    :country,
    :country_code,
    :label,
    :place_type,
    :match_score,
    :place_id,
    :address_number_corrected,
    :estimated_point_address,
    keyword_init: true
  ) do
    def coordinates
      [ latitude, longitude ] if latitude.present? && longitude.present?
    end

    def suggested_street
      [ address_number, street ].compact_blank.join(" ").presence
    end
  end

  Suggestion = Struct.new(:label, :street, :place_id, keyword_init: true)

  def initialize(setting, http: Net::HTTP)
    @setting = setting
    @http = http
  end

  def geocode(address)
    options = @setting.geocode_options
    body = {
      QueryText: address,
      MaxResults: options.fetch(:max_results, DEFAULT_MAX_RESULTS),
      IntendedUse: INTENDED_USE
    }
    body[:BiasPosition] = options[:bias_position] if options[:bias_position]

    parse_results(post("geocode", body).body)
  end

  def autocomplete(query)
    body = {
      QueryText: query,
      MaxResults: DEFAULT_MAX_RESULTS,
      IntendedUse: SUGGESTION_INTENDED_USE,
      AdditionalFeatures: [ "Core" ]
    }

    parse_suggestions(post("autocomplete", body).body)
  end

  private
    def post(path, body)
      region = @setting.aws_region.to_s.strip
      api_key = @setting.aws_location_api_key.to_s.strip
      raise Error, "Amazon Location Service region is not configured." if region.blank?
      raise Error, "Amazon Location Service API key is not configured." if api_key.blank?

      uri = URI(format("%s/%s", format(BASE_ENDPOINT, region), path))
      uri.query = URI.encode_www_form(key: api_key)

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request["Accept"] = "application/json"
      request.body = body.to_json

      response = @http.start(uri.host, uri.port, use_ssl: true, open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT) do |http|
        http.request(request)
      end

      return response if response.code.to_i.between?(200, 299)

      raise error_for(response)
    rescue Timeout::Error => error
      raise Error, "Amazon Location Service request timed out: #{error.message}"
    rescue SocketError, SystemCallError, OpenSSL::SSL::SSLError => error
      raise Error, "Amazon Location Service request failed: #{error.message}"
    rescue URI::InvalidURIError => error
      raise Error, "Amazon Location Service region is invalid: #{error.message}"
    end

    def parse_results(body)
      payload = JSON.parse(body.to_s)
      items = payload["ResultItems"]
      raise Error, "Amazon Location Service returned an invalid response." unless items.is_a?(Array)

      items.filter_map { |item| build_result(item) }
    rescue JSON::ParserError
      raise Error, "Amazon Location Service returned invalid JSON."
    end

    def parse_suggestions(body)
      payload = JSON.parse(body.to_s)
      items = payload["ResultItems"]
      raise Error, "Amazon Location Service returned an invalid response." unless items.is_a?(Array)

      items.filter_map { |item| build_suggestion(item) }
    rescue JSON::ParserError
      raise Error, "Amazon Location Service returned invalid JSON."
    end

    def build_result(item)
      position = item["Position"]
      return unless position.is_a?(Array) && position.length == 2
      return unless position.all? { |value| value.is_a?(Numeric) }

      address = item["Address"] || {}
      region = address["Region"] || {}
      country = address["Country"] || {}
      match_scores = item["MatchScores"] || {}

      Result.new(
        latitude: position[1].to_f,
        longitude: position[0].to_f,
        address_number: address["AddressNumber"].presence,
        street: address["Street"].presence,
        locality: address["Locality"].presence,
        region: region["Name"].presence || region["Code"].presence,
        region_code: region["Code"].presence,
        region_name: region["Name"].presence,
        postal_code: address["PostalCode"].presence,
        country: country["Name"].presence || country["Code3"].presence || country["Code2"].presence,
        country_code: country["Code2"].presence || country["Code3"].presence,
        label: address["Label"].presence || item["Title"].presence,
        place_type: item["PlaceType"].presence,
        match_score: match_scores["Overall"]&.to_f,
        place_id: item["PlaceId"].presence,
        address_number_corrected: item["AddressNumberCorrected"],
        estimated_point_address: item["EstimatedPointAddress"]
      )
    end

    def build_suggestion(item)
      address = item["Address"] || {}
      label = address["Label"].presence || item["Title"].presence
      street = [ address["AddressNumber"], address["Street"] ].compact_blank.join(" ").presence

      # The typeahead only fills the street field, so skip results that do not
      # contain a usable street component.
      return if street.blank?

      Suggestion.new(
        label: label.presence || street,
        street: street,
        place_id: item["PlaceId"].presence
      )
    end

    def error_for(response)
      payload = begin
        parsed = JSON.parse(response.body.to_s)
        parsed.is_a?(Hash) ? parsed : {}
      rescue JSON::ParserError
        {}
      end

      message = payload["message"].presence || payload["Message"].presence || response.message
      code = payload["reason"].presence || payload["code"].presence || response.code

      Error.new(
        "Amazon Location Service request failed (#{response.code}): #{message}",
        status: response.code.to_i,
        code: code,
        request_id: response["x-amzn-requestid"].presence,
        body: response.body.to_s.presence
      )
    end
end
