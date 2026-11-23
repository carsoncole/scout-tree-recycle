require "test_helper"

class GeocodableTest < ActiveSupport::TestCase
  test "records an error log with the Amazon Location response" do
    reservation = reservations(:routing_1)
    configure_location_service!
    error = location_service_error(
      message: "Place index not found: tree-recycle.",
      status: 400,
      body: "Place index not found: tree-recycle.",
      request_id: "req-123"
    )

    with_geocoder_error(error) do
      assert_difference -> { Log.where(log_type: "error").count }, 1 do
        assert_not reservation.full_geocode!
      end
    end

    log = Log.where(log_type: "error").order(:created_at).last
    assert_equal reservation.id, log.reservation_id
    assert_equal "Aws::LocationService::Errors::ResourceNotFoundException", log.error_type
    assert_equal "error", log.severity
    assert log.handled
    assert_equal "Place index not found: tree-recycle.", log.message
    assert_equal reservation.address, log.context["address"]
    assert_equal "ResourceNotFoundException", log.context["code"]
    assert_equal 400, log.context["status"]
    assert_equal "req-123", log.context["request_id"]
    assert_equal "ResourceNotFoundException", log.context["error_type"]
    assert_equal "Place index not found: tree-recycle.", log.context["response_body"]
    assert_equal "us-west-2", log.context["region"]
    assert_equal "tree_recycle", log.context["index_name"]
    assert_equal "Geocoding failed: Place index not found: tree-recycle.", reservation.geocode_failure_message
    assert reservation.reload.was_automatically_geocoded
    assert_nil reservation.latitude
  end

  test "a blank place index is rejected and reported instead of succeeding" do
    reservation = reservations(:routing_1)
    configure_location_service!
    Setting.instance.update!(aws_location_index_name: "")

    assert_difference -> { Log.where(log_type: "error", reservation_id: reservation.id).count }, 1 do
      assert_not reservation.full_geocode!
    end

    log = Log.where(log_type: "error", reservation_id: reservation.id).order(:created_at).last
    assert_equal "ArgumentError", log.error_type
    assert_equal ":index_name must not be blank", log.message
    assert_equal "Geocoding failed: :index_name must not be blank", reservation.geocode_failure_message
    assert_nil reservation.reload.latitude
    assert reservation.was_automatically_geocoded
  end

  test "returns false when the Amazon error cannot be logged" do
    reservation = reservations(:routing_1)
    configure_location_service!
    original_create = Log.method(:create)
    Log.define_singleton_method(:create) { |*| raise "db down" }

    with_geocoder_error(location_service_error) do
      assert_nothing_raised do
        assert_not reservation.full_geocode!
      end
    end
  ensure
    Log.define_singleton_method(:create, original_create) if original_create
  end

  test "geocodes with Places v2 and prefers a result with an address number" do
    reservation = reservations(:routing_1)
    configure_places_v2!
    results = [
      verified_address_result(latitude: 40.1, longitude: -74.1, address_number: nil),
      verified_address_result(latitude: 40.2, longitude: -74.2, address_number: "123")
    ]

    with_stubbed_location_search(results) do
      assert reservation.full_geocode!
    end

    reservation.reload
    assert_equal 40.2, reservation.latitude
    assert_equal(-74.2, reservation.longitude)
  end

  test "rejects Places v2 results outside the configured pickup area" do
    reservation = reservations(:routing_1)
    configure_places_v2!
    result = verified_address_result(
      locality: "Seattle",
      region: "Washington",
      region_code: "WA",
      region_name: "Washington"
    )

    with_stubbed_location_search([ result ]) do
      assert_not reservation.full_geocode!
    end

    assert_includes reservation.geocode_failure_message, "configured pickup area"
    reservation.reload
    assert_nil reservation.latitude
    assert reservation.geocoding_failed?
    assert_equal "Manual", reservation.routing_status
  end

  test "records a Places v2 error log" do
    reservation = reservations(:routing_1)
    configure_places_v2!
    error = LocationSearch::Error.new(
      "Forbidden",
      status: 403,
      code: "AccessDeniedException",
      request_id: "req-9",
      body: "{\"message\":\"Forbidden\"}"
    )

    with_stubbed_location_search_error(error) do
      assert_difference -> { Log.where(log_type: "error").count }, 1 do
        assert_not reservation.full_geocode!
      end
    end

    log = Log.where(log_type: "error").order(:created_at).last
    assert_equal "LocationSearch::Error", log.error_type
    assert_equal "places_v2", log.context["provider"]
    assert_equal 403, log.context["status"]
    assert_equal "AccessDeniedException", log.context["code"]
    assert_equal "req-9", log.context["request_id"]
    assert_includes log.context["response_body"], "Forbidden"
    assert_includes reservation.geocode_failure_message, "Forbidden"
  end

  test "reports when Places v2 returns no coordinates" do
    reservation = reservations(:routing_1)
    configure_places_v2!

    with_stubbed_location_search([]) do
      assert_not reservation.full_geocode!
    end

    assert_equal "Amazon Location Service did not return coordinates for this address.", reservation.geocode_failure_message
  end

  test "switching provider does not change existing coordinates" do
    reservation = reservations(:pending_pickup_1)
    latitude = reservation.latitude
    longitude = reservation.longitude

    Setting.instance.update!(
      location_provider: "places_v2",
      aws_location_api_key: "v1.public.test",
      aws_region: "us-west-2"
    )

    reservation.reload
    assert_equal latitude, reservation.latitude
    assert_equal longitude, reservation.longitude
  end

  private

  def location_service_error(message: "Place index not found.", status: 400, body: message, request_id: "req-1")
    response = Seahorse::Client::Http::Response.new(status_code: status)
    response.headers["x-amzn-requestid"] = request_id
    response.headers["x-amzn-errortype"] = "ResourceNotFoundException"
    response.body = body
    context = Seahorse::Client::RequestContext.new(http_response: response)
    error_class = Aws::LocationService::Errors::ResourceNotFoundException
    error_class.code = "ResourceNotFoundException"
    error_class.new(context, message)
  end

  def with_geocoder_error(error)
    original = Geocoder.method(:search)
    Geocoder.define_singleton_method(:search) { |*_args, **_kwargs| raise error }
    yield
  ensure
    Geocoder.define_singleton_method(:search, original) if original
  end
end
