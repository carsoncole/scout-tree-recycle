require "test_helper"

class MarketingMailerTest < ActionMailer::TestCase
  test "marketing_email_1" do
    Setting.instance.update(is_emailing_enabled: true)
    mail = MarketingMailer.with(prior_reservation_id: prior_reservations(:one).id).marketing_email_1
    assert_equal "Tree recycling #{ Setting.instance.event_pickup_start.strftime("%B %-d") }. Register today.", mail.subject
    assert_equal [ prior_reservations(:one).email ], mail.to
    assert_equal [ "example@example.com" ], mail.from
    assert_match "Register for a tree pickup!", mail.body.encoded
  end

  test "marketing_email_2" do
    Setting.instance.update(is_emailing_enabled: true)
    mail = MarketingMailer.with(prior_reservation_id: prior_reservations(:one).id).marketing_email_2
    assert_equal "Last call! Tree recycling #{ Setting.instance.event_pickup_start.strftime("%B %-d") }. Register today.", mail.subject
    assert_equal [ prior_reservations(:one).email ], mail.to
    assert_equal [ "example@example.com" ], mail.from
    assert_match "Reserve your Pickup Today", mail.body.encoded
  end
end
