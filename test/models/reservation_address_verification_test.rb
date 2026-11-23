require "test_helper"

class ReservationAddressVerificationTest < ActiveSupport::TestCase
  setup do
    @reservation = reservations(:reservation_form_minimum)
    configure_address_verification!
  end

  test "a strong match stores coordinates and normalized components without replacing the entered address" do
    original_street = @reservation.street

    result = verified_address_result
    assert with_stubbed_location_search([ result ]) { @reservation.verify_address! }

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
    assert_equal "123 Main Street", @reservation.suggested_street
    assert_equal "10001", @reservation.suggested_zip
  end

  test "a weak match stores a suggestion and leaves the reservation for confirmation" do
    result = verified_address_result(match_score: 0.62)
    assert_not with_stubbed_location_search([ result ]) { @reservation.verify_address! }

    @reservation.reload
    assert @reservation.address_verification_suggested?
    assert_equal 0.62, @reservation.address_match_score
    assert_nil @reservation.address_verified_at
    assert @reservation.suggested_address_complete?
    assert_equal "123 Main Street", @reservation.suggested_street
  end

  test "a corrected address number is suggested instead of automatically verified" do
    result = verified_address_result(address_number_corrected: true)
    assert_not with_stubbed_location_search([ result ]) { @reservation.verify_address! }

    assert @reservation.reload.address_verification_suggested?
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

  test "applying the suggested address updates the pickup address" do
    suggestion = verified_address_result(match_score: 0.62)
    with_stubbed_location_search([ suggestion ]) { @reservation.verify_address! }
    assert @reservation.reload.address_verification_suggested?

    assert @reservation.apply_suggested_address!

    @reservation.reload
    assert @reservation.address_match_verified?
    assert_equal "123 Main Street", @reservation.street
    assert_equal "123", @reservation.house_number
    assert_equal "Main Street", @reservation.street_name
    assert_equal "New York", @reservation.city
    assert_equal "New York", @reservation.state
    assert_equal "10001", @reservation.zip
    assert_equal "United States", @reservation.country
    assert_not_nil @reservation.address_verified_at
  end

  test "keeping the entered address records an override" do
    suggestion = verified_address_result(match_score: 0.62)
    with_stubbed_location_search([ suggestion ]) { @reservation.verify_address! }

    assert @reservation.keep_entered_address!

    @reservation.reload
    assert @reservation.address_match_overridden?
    assert_equal "350 5th Ave", @reservation.street
    assert_not_nil @reservation.address_verified_at
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
