require "test_helper"

class LocationSearchTest < ActiveSupport::TestCase
  setup do
    @setting = settings(:one)
    @setting.update!(
      location_provider: "places_v2",
      aws_location_api_key: "v1.public.test",
      aws_region: "us-west-2"
    )
  end

  test "maps Geocode results and match scores" do
    response = fake_response(
      200,
      { "ResultItems" => [
        {
          "Position" => [ -74.0, 40.7 ],
          "Address" => {
            "AddressNumber" => "123",
            "Street" => "Main Street",
            "Locality" => "New York",
            "Region" => { "Code" => "NY", "Name" => "New York" },
            "PostalCode" => "10001",
            "Country" => { "Code2" => "US", "Code3" => "USA", "Name" => "United States" },
            "Label" => "123 Main Street, New York, NY 10001, United States"
          },
          "PlaceType" => "PointAddress",
          "PlaceId" => "place-123",
          "MatchScores" => { "Overall" => 0.97 },
          "AddressNumberCorrected" => false,
          "EstimatedPointAddress" => false
        },
        {
          "Position" => [ -74.1, 40.8 ],
          "Address" => { "Street" => "Main Street", "Label" => "Main Street" },
          "PlaceType" => "Street"
        }
      ] }
    )

    results = geocode(response)

    assert_equal 2, results.size
    result = results.first
    assert_equal 40.7, result.latitude
    assert_equal(-74.0, result.longitude)
    assert_equal "123", result.address_number
    assert_equal "Main Street", result.street
    assert_equal "New York", result.locality
    assert_equal "New York", result.region
    assert_equal "10001", result.postal_code
    assert_equal "United States", result.country
    assert_equal "123 Main Street", result.suggested_street
    assert_equal "PointAddress", result.place_type
    assert_in_delta 0.97, result.match_score, 0.001
    assert_equal "place-123", result.place_id
    assert_not result.address_number_corrected
    assert_not result.estimated_point_address
    assert_nil results.second.address_number
    assert_nil results.second.match_score
  end

  test "sends Storage, MaxResults, and the route-area bias position" do
    http = FakeHttp.new(fake_response(200, { "ResultItems" => [] }))

    LocationSearch.new(@setting, http: http).geocode("123 Main St")

    body = JSON.parse(http.sent_request.body)
    assert_equal "123 Main St", body["QueryText"]
    assert_equal 5, body["MaxResults"]
    assert_equal "Storage", body["IntendedUse"]
    assert_equal @setting.geocode_options[:bias_position], body["BiasPosition"]
    assert body["BiasPosition"].all? { |value| value.is_a?(Numeric) }
    assert_equal "v1.public.test", URI.decode_www_form(http.sent_request.uri.query).to_h["key"]
    assert_equal "places.geo.us-west-2.amazonaws.com", http.sent_request.uri.host
    assert_equal "/v2/geocode", http.sent_request.uri.path
  end

  test "omits the bias position when there are no route points" do
    Point.delete_all
    http = FakeHttp.new(fake_response(200, { "ResultItems" => [] }))

    LocationSearch.new(@setting, http: http).geocode("123 Main St")

    assert_not JSON.parse(http.sent_request.body).key?("BiasPosition")
  end

  test "raises a normalized error for a failed response" do
    response = fake_response(
      403,
      { "message" => "Forbidden", "reason" => "AccessDeniedException" }.to_json,
      headers: { "x-amzn-requestid" => "req-1" }
    )

    error = assert_raises(LocationSearch::Error) do
      LocationSearch.new(@setting, http: FakeHttp.new(response)).geocode("123 Main St")
    end

    assert_equal 403, error.status
    assert_equal "AccessDeniedException", error.code
    assert_equal "req-1", error.request_id
    assert_includes error.message, "Amazon Location Service request failed (403)"
    assert_includes error.body, "Forbidden"
  end

  test "raises an error for malformed JSON" do
    assert_raises LocationSearch::Error do
      geocode(fake_response(200, "not json"))
    end
  end

  test "raises an error when ResultItems is missing" do
    error = assert_raises(LocationSearch::Error) do
      geocode(fake_response(200, { "message" => "unexpected" }.to_json))
    end

    assert_includes error.message, "invalid response"
  end

  test "raises an error when the request times out" do
    error = assert_raises(LocationSearch::Error) do
      LocationSearch.new(@setting, http: TimeoutHttp.new).geocode("123 Main St")
    end

    assert_includes error.message, "timed out"
  end

  test "requires an API key and region" do
    @setting.update!(aws_location_api_key: nil)

    error = assert_raises(LocationSearch::Error) do
      geocode(fake_response(200, { "ResultItems" => [] }))
    end

    assert_includes error.message, "API key is not configured"
  end

  private
    def geocode(response)
      LocationSearch.new(@setting, http: FakeHttp.new(response)).geocode("123 Main St")
    end

    def fake_response(code, body, headers: {})
      body = body.to_json unless body.is_a?(String)
      FakeResponse.new(code: code, body: body, headers: headers)
    end

    class FakeResponse
      attr_reader :code, :body, :message

      def initialize(code:, body:, headers: {}, message: "Request failed")
        @code = code.to_s
        @body = body
        @headers = headers
        @message = message
      end

      def [](name)
        @headers[name]
      end
    end

    class FakeHttp
      attr_reader :sent_request

      def initialize(response)
        @response = response
      end

      def start(_host, _port, use_ssl:, open_timeout:, read_timeout:)
        yield self
      end

      def request(req)
        @sent_request = req
        @response
      end
    end

    class TimeoutHttp
      def start(*, **)
        raise Net::OpenTimeout
      end
    end
end
