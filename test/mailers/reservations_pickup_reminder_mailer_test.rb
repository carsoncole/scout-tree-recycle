require "test_helper"

class ReservationsPickupReminderMailerTest < ActionMailer::TestCase
  setup do
    Setting.instance.update(is_emailing_enabled: true)
    @reservation = reservations(:pending_pickup_not_routed)
  end

  test "includes pickup details, preparation instructions, donation options, and update links" do
    email = ReservationsMailer.with(reservation_id: @reservation.id).pickup_reminder_email

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ @reservation.email ], email.to
    assert_equal "Reminder: Tree pickup on #{pickup_start_weekday}", email.subject
    body = readable_mail_body(email)
    assert_includes body, @reservation.street
    assert_includes body, @reservation.pickup_notes
    assert_includes body, Setting.instance.pickup_instructions_text
    assert_includes body, "out and ready by #{pickup_start_time}"
    assert_includes body, "fundraiser for #{Setting.instance.organization_name}"
    assert_includes body, "donation of $#{Setting.instance.suggested_donation_amount}"
    assert_includes body, "make checks payable to #{Setting.instance.organization_name}"
    assert_includes body, "place your donation in an envelope"
    assert_includes body, "place that envelope in a baggie"
    assert_includes body, "secure the baggie to your tree"
    assert_includes body, "/reservations/#{@reservation.public_token}/donations/new"
    assert_includes body, "/reservations/#{@reservation.public_token}/edit"
  end

  test "omits donation requests when a donation was already received" do
    reservation = reservations(:pending_pickup_1)
    Donation.create!(reservation: reservation, amount: 100, payment_status: "paid", form: :online)
    email = ReservationsMailer.with(reservation_id: reservation.id).pickup_reminder_email
    email.deliver_now

    body = readable_mail_body(email)
    assert_not_includes body, "Support our fundraiser"
    assert_not_includes body, "make checks payable"
  end

  test "marks the reminder as sent and does not send it again" do
    assert_emails 1 do
      ReservationsMailer.with(reservation_id: @reservation.id).pickup_reminder_email.deliver_now
    end
    assert @reservation.reload.pickup_reminder_email_sent_at.present?

    assert_no_emails do
      ReservationsMailer.with(reservation_id: @reservation.id).pickup_reminder_email.deliver_now
    end
  end

  test "does not send to a reservation that is no longer active" do
    @reservation.update_column(:status, Reservation.statuses[:cancelled])
    email = ReservationsMailer.with(reservation_id: @reservation.id).pickup_reminder_email

    assert_no_emails do
      email.deliver_now
    end
    assert_nil @reservation.reload.pickup_reminder_email_sent_at
  end

  test "does not send or mark the reservation when the template is unpublished" do
    reservation_email_templates(:pickup_reminder_email).unpublish!
    email = ReservationsMailer.with(reservation_id: @reservation.id).pickup_reminder_email

    assert_no_emails do
      email.deliver_now
    end
    assert_nil @reservation.reload.pickup_reminder_email_sent_at
  end

  private

  def readable_mail_body(email)
    [ email.text_part, email.html_part ].compact.map { |part| part.body.decoded }.join("\n").presence || email.body.decoded
  end

  def pickup_start_time
    Setting.instance.event_pickup_start.in_time_zone(Setting.instance.time_zone).strftime("%-l:%M%P")
  end

  def pickup_start_weekday
    Setting.instance.event_pickup_start.in_time_zone(Setting.instance.time_zone).strftime("%A, %B %-d")
  end
end
