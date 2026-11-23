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

  test "maps SearchText results" do
    response = fake_response(
      200,
      { "ResultItems" => [
        {
          "Position" => [ -74.0, 40.7 ],
          "Address" => { "AddressNumber" => "123", "Label" => "123 Main St" },
          "PlaceType" => "PointAddress"
        },
        {
          "Position" => [ -74.1, 40.8 ],
          "Address" => { "Label" => "Main St" },
          "PlaceType" => "Street"
        }
      ] }
    )

    results = search(response)

    assert_equal 2, results.size
    assert_equal 40.7, results.first.latitude
    assert_equal(-74.0, results.first.longitude)
    assert_equal "123", results.first.address_number
    assert_equal "123 Main St", results.first.label
    assert_equal "PointAddress", results.first.place_type
    assert_nil results.second.address_number
  end

  test "sends Storage, MaxResults, and the route bounding box" do
    http = FakeHttp.new(fake_response(200, { "ResultItems" => [] }))

    LocationSearch.new(@setting, http: http).search("123 Main St")

    body = JSON.parse(http.sent_request.body)
    assert_equal "123 Main St", body["QueryText"]
    assert_equal 5, body["MaxResults"]
    assert_equal "Storage", body["IntendedUse"]
    assert_equal @setting.location_search_options[:filter_b_box], body["Filter"]["BoundingBox"]
    assert_equal "v1.public.test", URI.decode_www_form(http.sent_request.uri.query).to_h["key"]
    assert_equal "places.geo.us-west-2.amazonaws.com", http.sent_request.uri.host
    assert_equal "/v2/search-text", http.sent_request.uri.path
  end

  test "omits the filter when there are no route points" do
    Point.delete_all
    http = FakeHttp.new(fake_response(200, { "ResultItems" => [] }))

    LocationSearch.new(@setting, http: http).search("123 Main St")

    assert_not JSON.parse(http.sent_request.body).key?("Filter")
  end

  test "raises a normalized error for a failed response" do
    response = fake_response(
      403,
      { "message" => "Forbidden", "reason" => "AccessDeniedException" }.to_json,
      headers: { "x-amzn-requestid" => "req-1" }
    )

    error = assert_raises(LocationSearch::Error) do
      LocationSearch.new(@setting, http: FakeHttp.new(response)).search("123 Main St")
    end

    assert_equal 403, error.status
    assert_equal "AccessDeniedException", error.code
    assert_equal "req-1", error.request_id
    assert_includes error.message, "Amazon Location Service request failed (403)"
    assert_includes error.body, "Forbidden"
  end

  test "raises an error for malformed JSON" do
    assert_raises LocationSearch::Error do
      search(fake_response(200, "not json"))
    end
  end

  test "raises an error when ResultItems is missing" do
    error = assert_raises(LocationSearch::Error) do
      search(fake_response(200, { "message" => "unexpected" }.to_json))
    end

    assert_includes error.message, "invalid response"
  end

  test "raises an error when the request times out" do
    error = assert_raises(LocationSearch::Error) do
      LocationSearch.new(@setting, http: TimeoutHttp.new).search("123 Main St")
    end

    assert_includes error.message, "timed out"
  end

  test "requires an API key and region" do
    @setting.update!(aws_location_api_key: nil)

    error = assert_raises(LocationSearch::Error) do
      search(fake_response(200, { "ResultItems" => [] }))
    end

    assert_includes error.message, "API key is not configured"
  end

  private
    def search(response)
      LocationSearch.new(@setting, http: FakeHttp.new(response)).search("123 Main St")
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
