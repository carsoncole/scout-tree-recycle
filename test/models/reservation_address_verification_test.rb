require "test_helper"

class ReservationAddressVerificationTest < ActiveSupport::TestCase
  setup do
    @reservation = reservations(:reservation_form_minimum)
    configure_address_verification!
  end

  test "an in-area match stores coordinates without replacing the entered address" do
    original_street = @reservation.street

    assert with_stubbed_location_search([ verified_address_result ]) { @reservation.verify_address! }

    @reservation.reload
    assert @reservation.address_match_verified?
    assert_equal original_street, @reservation.street
    assert_equal original_street, @reservation.submitted_address.split(",").first
    assert_equal "123 Main Street, New York, NY 10001, United States", @reservation.formatted_address
    assert_equal "place-123", @reservation.geo_place_id
    assert_in_delta 0.98, @reservation.address_match_score, 0.001
    assert_not_nil @reservation.address_verified_at
    assert @reservation.geocoded?
    assert_equal 40.7128, @reservation.latitude
    assert_equal(-74.0060, @reservation.longitude)
  end

  test "a lower-scoring in-area match is still accepted silently" do
    result = verified_address_result(match_score: 0.55)

    assert with_stubbed_location_search([ result ]) { @reservation.verify_address! }

    @reservation.reload
    assert @reservation.address_match_verified?
    assert_equal 0.55, @reservation.address_match_score
    assert @reservation.geocoded?
  end

  test "an out-of-area match is rejected and leaves no coordinates" do
    result = verified_address_result(
      locality: "Seattle",
      region: "Washington",
      region_code: "WA",
      region_name: "Washington",
      label: "123 Main Street, Seattle, WA 98101, United States"
    )

    assert_not with_stubbed_location_search([ result ]) { @reservation.verify_address! }

    @reservation.reload
    assert @reservation.address_match_unavailable?
    assert_nil @reservation.latitude
    assert_nil @reservation.longitude
    assert_nil @reservation.address_verified_at
    assert_equal @reservation.street, @reservation.submitted_address.split(",").first
  end

  test "no result marks verification unavailable without blocking the reservation" do
    assert_not with_stubbed_location_search([]) { @reservation.verify_address! }

    @reservation.reload
    assert @reservation.address_match_unavailable?
    assert_nil @reservation.address_verified_at
    assert_nil @reservation.latitude
    assert_equal @reservation.street, @reservation.submitted_address.split(",").first
  end

  test "legacy provider skips Places v2 verification" do
    Setting.instance.update!(
      location_provider: "places_v1",
      aws_access_key_id: "AKIATEST",
      aws_secret_access_key: "secret",
      aws_location_index_name: "tree_recycle"
    )

    assert_not @reservation.verify_address!
    assert @reservation.reload.address_match_unavailable?
    assert_equal @reservation.street, @reservation.submitted_address.split(",").first
  end

  test "changing the street clears stored verification data" do
    with_stubbed_location_search([ verified_address_result ]) { @reservation.verify_address! }
    assert @reservation.reload.address_match_verified?

    @reservation.update!(street: "500 New Address Ave")

    @reservation.reload
    assert_nil @reservation.address_match_status
    assert_nil @reservation.address_match_score
    assert_nil @reservation.geo_place_id
    assert_nil @reservation.formatted_address
    assert_nil @reservation.suggested_street
  end
end
