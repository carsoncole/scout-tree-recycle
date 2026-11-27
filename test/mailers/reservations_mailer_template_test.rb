require "test_helper"

class ReservationsMailerTemplateTest < ActionMailer::TestCase
  setup do
    Setting.instance.update(is_emailing_enabled: true)
    @reservation = reservations(:pending_pickup_no_mobile)
    @reservation.update_columns(confirmed_reservation_email_sent_at: nil)
  end

  test "uses the published reservation template content" do
    template = reservation_email_templates(:new_reservation_email)
    template.update!(subject: "Draft subject", body_html: "<p>Draft body</p>")

    email = ReservationsMailer.with(reservation_id: @reservation.id).new_reservation_email

    assert_emails 1 do
      email.deliver_now
    end
    assert_equal "Your tree pickup is confirmed", email.subject
    body = email.html_part.body.decoded
    assert_includes body, "Tree pick-up scheduled"
    assert_not_includes body, "Draft body"
    assert_match(/src="data:image\/[^;]+;base64,[^"]+"/, body)
  end

  test "uses the published logo width and missing tree template" do
    email = ReservationsMailer.with(reservation_id: reservations(:missing_1).id).missing_tree_email

    assert_emails 1 do
      email.deliver_now
    end
    assert_match(/src="data:image\/[^;]+;base64,[^"]+"/, email.html_part.body.decoded)
  end

  test "does not send when the template is unpublished" do
    template = reservation_email_templates(:new_reservation_email)
    template.update!(published_at: nil)

    email = ReservationsMailer.with(reservation_id: @reservation.id).new_reservation_email

    assert_no_emails do
      email.deliver_now
    end
    assert_nil @reservation.reload.confirmed_reservation_email_sent_at
  end

  test "does not raise when emailing is disabled" do
    Setting.instance.update(is_emailing_enabled: false)

    email = ReservationsMailer.with(reservation_id: @reservation.id).new_reservation_email

    assert_no_emails do
      email.deliver_now
    end
    assert_nil @reservation.reload.confirmed_reservation_email_sent_at
  end

  test "does not raise when the email was already sent" do
    @reservation.update_columns(confirmed_reservation_email_sent_at: 1.day.ago)

    email = ReservationsMailer.with(reservation_id: @reservation.id).new_reservation_email

    assert_no_emails do
      email.deliver_now
    end
  end

  test "does not send when the template is missing" do
    ReservationEmailTemplate.find_by!(name: "new_reservation_email").destroy!

    email = ReservationsMailer.with(reservation_id: @reservation.id).new_reservation_email

    assert_no_emails do
      email.deliver_now
    end
    assert_nil @reservation.reload.confirmed_reservation_email_sent_at
  end

  test "test email renders the draft without updating send dates" do
    template = reservation_email_templates(:new_reservation_email)
    template.update!(subject: "Draft subject", body_html: "<p>Draft body for {{ reservation.name }}</p>")

    email = ReservationsMailer.with(
      template_id: template.id,
      reservation_id: @reservation.id,
      email: "admin@example.com",
      source: "draft"
    ).test_email

    assert_emails 1 do
      email.deliver_now
    end
    assert_equal [ "admin@example.com" ], email.to
    assert_equal "[TEST] Draft subject", email.subject
    assert_includes email.html_part.body.decoded, "Draft body for Mack Gilbert"
    assert_nil @reservation.reload.confirmed_reservation_email_sent_at
  end

  test "test email can render the missing tree follow-up version" do
    template = reservation_email_templates(:missing_tree_email)

    email = ReservationsMailer.with(
      template_id: template.id,
      reservation_id: @reservation.id,
      email: "admin@example.com",
      source: "draft",
      follow_up: "1"
    ).test_email

    assert_emails 1 do
      email.deliver_now
    end
    assert_equal "[TEST] Follow-up: We still cannot find your tree", email.subject
    assert_includes email.html_part.body.decoded, "We visited again today"
  end
end
