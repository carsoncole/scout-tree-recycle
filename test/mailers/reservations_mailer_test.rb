require "test_helper"

class ReservationsMailerTest < ActionMailer::TestCase
  setup do
    Setting.instance.update(is_emailing_enabled: true)
  end

  test "sends confirmation email once completed reservation is created" do
    assert_emails 0 do
      @reservation = reservations(:address_verification_1)
    end

    assert_emails 0 do
      @reservation.donation!
    end

    assert_emails 1 do
      @reservation.routing!
    end

    assert @reservation.reload.confirmed_reservation_email_sent_at.present?
  end

  test "confirmation email" do
    Setting.instance.update(is_emailing_enabled: true)
    reservation = reservations(:pending_pickup_1)
    reservation.update_column(:confirmed_reservation_email_sent_at, nil)
    email = ReservationsMailer.with(reservation_id: reservation.id).new_reservation_email

    assert_emails 1 do
      email.deliver_now
    end
    assert_equal [ reservation.email ], email.to
    assert_equal [ "example@example.com" ], email.from
    assert_equal "Your tree pickup is confirmed", email.subject
    assert_match "Tree pick-up scheduled", email.body.encoded
  end

  test "sends cancellation reservation email once cancelled" do
    assert_emails 0 do
      @reservation = reservations(:routing_1)
    end

    assert_emails 1 do
      @reservation.cancelled!
    end

    assert @reservation.reload.cancelled_reservation_email_sent_at.present?
  end

  test "cancelled reservation email" do
    reservation = reservations(:pending_pickup_1)
    email = ReservationsMailer.with(reservation_id: reservation.id).cancelled_reservation_email
    assert_emails 1 do
      email.deliver_now
    end
    assert_equal [ reservation.email ], email.to
    assert_equal [ "example@example.com" ], email.from
    assert_equal "Your tree pickup reservation has been cancelled", email.subject
    assert_match "Tree pick-up cancelled", email.body.encoded
  end

  test "not sending more than one confirmation email" do
    Setting.instance.update(is_routing_enabled: true)
    configure_location_service!
    reservation = reservations(:address_verification_1)

    with_stubbed_geocoding do
      assert_emails 1 do
        perform_enqueued_jobs do
          reservation.routing!
        end
      end
    end

    assert reservation.reload.confirmed_reservation_email_sent_at.present?
    assert reservation.pending_pickup?
    assert_emails 0 do
      reservation.routing!
    end
  end

  test "confirmation email sent when status is changed to routing" do
    reservation = reservations(:donation_1)
    assert_emails 1 do
      reservation.routing!
    end
    email = ActionMailer::Base.deliveries.last
    assert_equal [ reservation.email ], email.to
    assert_equal [ "example@example.com" ], email.from
    assert_equal "Your tree pickup is confirmed", email.subject
    assert_match "Tree pick-up scheduled", email.body.encoded
  end

  test "cancelled reservation email sent when status is changed to cancelled" do
    reservation = reservations(:pending_pickup_1)
    assert_emails 1 do
      reservation.cancelled!
    end
    email = ActionMailer::Base.deliveries.last
    assert_equal [ reservation.email ], email.to
    assert_equal [ "example@example.com" ], email.from
    assert_equal "Your tree pickup reservation has been cancelled", email.subject
    assert_match "Tree pick-up cancelled", email.body.encoded
  end

  test "not sending more than one cancellation email" do
    reservation = reservations(:pending_pickup_1)
    assert_emails 1 do
      perform_enqueued_jobs do
        reservation.cancelled!
      end
    end
    assert reservation.reload.cancelled_reservation_email_sent_at.present?
    assert reservation.cancelled?
    assert_emails 0 do
      reservation.pending_pickup!
      reservation.cancelled!
    end
  end

  test "mailers for all statuses" do
    reservation = Reservation.new(status: :reservation_form, email: "test99@example.com", name: "Test User", street: "123 Main St", city: "Anytown", state: "CA", zip: "12345", mobile: "123-456-7890", pickup_notes: "Pickup notes")

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
