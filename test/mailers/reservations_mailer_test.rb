require "test_helper"

class ReservationsMailerTest < ActionMailer::TestCase

  test 'sends confirmation email once completed reservation is created' do
    assert_emails 0 do
      @reservation = create(:reservation, status: :address_verification)
    end

    assert_emails 0 do
      @reservation.donation!
    end

    assert_emails 1 do
      @reservation.routing!
    end

  end

  test "confirmation email" do
    reservation = create(:pending_pickup_reservation)
    email = ReservationsMailer.with(reservation_id: reservation.id).new_reservation_email

    assert_emails 1 do
      email.deliver_now
    end
    assert_equal [reservation.email], email.to
    assert_equal ["example@example.com"], email.from
    assert_equal "Your tree pickup is confirmed", email.subject
    assert_match "Tree pick-up scheduled", email.body.encoded
  end

  test "cancelled reservation email" do
    reservation = create(:pending_pickup_reservation)
    email = ReservationsMailer.with(reservation_id: reservation.id).cancelled_reservation_email
    assert_emails 1 do
      email.deliver_now
    end
    assert_equal [reservation.email], email.to
    assert_equal ["example@example.com"], email.from
    assert_equal "Your tree pickup reservation has been cancelled", email.subject 
    assert_match "Tree pick-up cancelled", email.body.encoded
  end


  test "confirmation email sent when status is changed to routing" do
    reservation = create(:reservation, status: :donation)
    assert_emails 1 do
      reservation.routing!
    end
    email = ActionMailer::Base.deliveries.last
    assert_equal [reservation.email], email.to
    assert_equal ["example@example.com"], email.from
    assert_equal "Your tree pickup is confirmed", email.subject
    assert_match "Tree pick-up scheduled", email.body.encoded
  end

  test "confirmation email not sent when status is not changed to routing" do
    reservation = create(:reservation, status: :donation)
    assert_no_emails do
      reservation.pending_pickup!
    end
  end

  test "cancelled reservation email sent when status is changed to cancelled" do
    reservation = create(:reservation, status: :pending_pickup)
    assert_emails 1 do
      reservation.cancelled!
    end
    email = ActionMailer::Base.deliveries.last
    assert_equal [reservation.email], email.to
    assert_equal ["example@example.com"], email.from
    assert_equal "Your tree pickup reservation has been cancelled", email.subject
    assert_match "Tree pick-up cancelled", email.body.encoded
  end

  test "mailers for all statuses" do
    reservation = build(:reservation, status: :reservation_form)

    assert_emails 0 do
      reservation.save!
    end

    assert_emails 0 do
      reservation.address_verification!
    end

    assert_emails 0 do
      reservation.donation!
    end

    assert_emails 1 do
      reservation.routing!
      assert_equal ActionMailer::Base.deliveries.last.subject, "Your tree pickup is confirmed"
    end

    assert_emails 0 do
      reservation.pending_pickup!
    end

    assert_emails 0 do
      reservation.picked_up!
    end

    assert_emails 0 do
      reservation.missing!
    end

    assert_emails 1 do
      reservation.cancelled!
      assert_equal ActionMailer::Base.deliveries.last.subject, "Your tree pickup reservation has been cancelled"
    end
  end
end

