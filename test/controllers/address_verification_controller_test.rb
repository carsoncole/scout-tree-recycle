require "test_helper"

class AddressVerificationControllerTest < ActionDispatch::IntegrationTest
  test "address verification" do
    Setting.instance.update(is_donations_enabled: true)
    get reservation_address_verification_url(reservations(:address_verification_1))
    assert_redirected_to new_reservation_donation_url(reservations(:address_verification_1))
  end

  test "address verification with disabled donations" do
    Setting.instance.update(is_donations_enabled: false)
    get reservation_address_verification_url(reservations(:address_verification_1))
    assert_redirected_to reservation_donations_url(reservations(:address_verification_1))
  end
end
