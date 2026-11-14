require "test_helper"

class PriorReservationTest < ActiveSupport::TestCase
  test "is valid" do
    assert prior_reservations(:full).valid?
  end

  test "is invalid without email" do
    prior_reservation = prior_reservations(:full)
    prior_reservation.email = nil
    assert_not prior_reservation.valid?
  end

  test "is invalid without name" do
    prior_reservation = prior_reservations(:full)
    prior_reservation.name = nil
    assert_not prior_reservation.valid?
  end

  test "email is downcased" do
    prior_reservation = prior_reservations(:full)
    prior_reservation.email = "JohnDoe@example.com"
    prior_reservation.save
    assert_equal "johndoe@example.com", prior_reservation.email
  end

  test "removing old prior reservations" do
    reservation = prior_reservations(:full)
    reservation.update(created_at: (Setting.instance.prior_reservation_retention_months + 1).months.ago)
    PriorReservation.remove_old_prior_reservations!
    assert_not PriorReservation.find_by(id: reservation.id)
  end

  test "marketing email cooldown is active within the configured window" do
    prior_reservation = prior_reservations(:full)
    prior_reservation.update(marketing_1_email_sent_at: 1.day.ago)

    assert prior_reservation.marketing_email_cooldown_active?

    Setting.instance.update(marketing_email_cooldown_days: 0)
    assert_not prior_reservation.marketing_email_cooldown_active?
  end

  test "clearing email flags" do
    prior_reservation = prior_reservations(:full)
    prior_reservation.update(marketing_1_email_sent_at: 1.day.ago, marketing_2_email_sent_at: 1.day.ago)
    PriorReservation.clear_email_flags!
    assert_nil prior_reservation.reload.marketing_1_email_sent_at
    assert_nil prior_reservation.marketing_2_email_sent_at
  end
end
