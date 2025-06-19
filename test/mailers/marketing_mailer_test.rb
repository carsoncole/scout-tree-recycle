require "test_helper"

class MarketingMailerTest < ActionMailer::TestCase
  include ActionDispatch::Routing::UrlFor
  include Rails.application.routes.url_helpers

  setup do
    @default_url_options = { host: "example.com" }
  end

  test "marketing_email_1" do
    Setting.instance.update(is_emailing_enabled: true)
    mail = MarketingMailer.with(prior_reservation_id: prior_reservations(:full).id).marketing_email_1
    assert_equal "Tree recycling #{ Setting.instance.event_pickup_start.strftime("%B %-d") }. Register today.", mail.subject
    assert_equal [ prior_reservations(:full).email ], mail.to
    assert_equal [ "example@example.com" ], mail.from
    assert_match "Register for a tree pickup!", mail.body.encoded
  end

  test "marketing_email_2" do
    Setting.instance.update(is_emailing_enabled: true)
    mail = MarketingMailer.with(prior_reservation_id: prior_reservations(:full).id).marketing_email_2
    assert_equal "Last call! Tree recycling #{ Setting.instance.event_pickup_start.strftime("%B %-d") }. Register today.", mail.subject
    assert_equal [ prior_reservations(:full).email ], mail.to
    assert_equal [ "example@example.com" ], mail.from
    assert_match "Reserve your Pickup Today", mail.body.encoded
  end

  test "marketing_email_1 contains unsubscribe link" do
    Setting.instance.update(is_emailing_enabled: true)
    prior_reservation = prior_reservations(:full)
    mail = MarketingMailer.with(prior_reservation_id: prior_reservation.id).marketing_email_1
    
    assert_match "Unsubscribe", mail.body.encoded
    assert_match unsubscribe_prior_reservation_url(prior_reservation), mail.body.encoded
  end

  test "marketing_email_2 contains unsubscribe link" do
    Setting.instance.update(is_emailing_enabled: true)
    prior_reservation = prior_reservations(:full)
    mail = MarketingMailer.with(prior_reservation_id: prior_reservation.id).marketing_email_2
    
    assert_match "Unsubscribe", mail.body.encoded
    assert_match unsubscribe_prior_reservation_url(prior_reservation), mail.body.encoded
  end

  test "marketing_email_1 contains registration link" do
    Setting.instance.update(is_emailing_enabled: true)
    prior_reservation = prior_reservations(:full)
    mail = MarketingMailer.with(prior_reservation_id: prior_reservation.id).marketing_email_1
    
    # Note: HTML encoding converts & to &amp; in the email body
    assert_match "Register for a tree pickup", mail.body.encoded
    assert_match "http://example.com", mail.body.encoded
    assert_match "prior_reservation_id=#{prior_reservation.id}", mail.body.encoded
  end

  test "marketing_email_2 contains registration link" do
    Setting.instance.update(is_emailing_enabled: true)
    prior_reservation = prior_reservations(:full)
    mail = MarketingMailer.with(prior_reservation_id: prior_reservation.id).marketing_email_2
    
    # Note: HTML encoding converts & to &amp; in the email body
    assert_match "Register for a tree pickup", mail.body.encoded
    assert_match "http://example.com", mail.body.encoded
    assert_match "prior_reservation_id=#{prior_reservation.id}", mail.body.encoded
  end
end
