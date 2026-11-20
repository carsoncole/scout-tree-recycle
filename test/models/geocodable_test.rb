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
