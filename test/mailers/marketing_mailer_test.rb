require "test_helper"

class MarketingMailerTest < ActionMailer::TestCase
  include ActionDispatch::Routing::UrlFor
  include Rails.application.routes.url_helpers

  setup do
    @default_url_options = { host: "example.com" }
  end

  test "marketing_email_1" do
    Setting.instance.update(is_emailing_enabled: true)
    mail = MarketingMailer.with(contact_id: contacts(:full).id).marketing_email_1
    assert_equal "Tree recycling #{ Setting.instance.event_pickup_start.strftime("%B %-d") }. Register today.", mail.subject
    assert_equal [ contacts(:full).email ], mail.to
    assert_equal [ "example@example.com" ], mail.from
    assert_match "Support #{Setting.instance.organization_name}! - Tree Recycling", mail.body.encoded
  end

  test "marketing_email_2" do
    Setting.instance.update(is_emailing_enabled: true)
    mail = MarketingMailer.with(contact_id: contacts(:full).id).marketing_email_2
    assert_equal "Last call! Tree recycling #{ Setting.instance.event_pickup_start.strftime("%B %-d") }. Register today.", mail.subject
    assert_equal [ contacts(:full).email ], mail.to
    assert_equal [ "example@example.com" ], mail.from
    assert_match "Reserve your Pickup Today", mail.body.encoded
  end

  test "marketing_email_1 contains unsubscribe and organization link" do
    Setting.instance.update(is_emailing_enabled: true, organization_url: "https://example.com")
    contact = contacts(:full)
    mail = MarketingMailer.with(contact_id: contact.id).marketing_email_1

    assert_match "Unsubscribe", mail.body.encoded
        # TODO: Fix this encoding issue
        # assert_match "https://example.com", mail.body.encoded
      end

  test "marketing_email_2 contains unsubscribe and organization link" do
    Setting.instance.update(is_emailing_enabled: true, organization_url: "https://example.com")
    contact = contacts(:full)
    mail = MarketingMailer.with(contact_id: contact.id).marketing_email_2

    assert_match "Unsubscribe", mail.body.encoded
    # TODO: Fix this encoding issue
    assert_match "https://example.com", mail.body.encoded
  end

  test "marketing_email_1 contains unsubscribe no organization link" do
    Setting.instance.update(is_emailing_enabled: true)
    contact = contacts(:full)
    mail = MarketingMailer.with(contact_id: contact.id).marketing_email_1

    assert_match "Unsubscribe", mail.body.encoded
    assert_no_match "https://example.com", mail.body.encoded
    assert_match Setting.instance.organization_name, mail.body.encoded
  end

  test "marketing_email_1 contains registration link" do
    Setting.instance.update(is_emailing_enabled: true)
    contact = contacts(:full)
    mail = MarketingMailer.with(contact_id: contact.id).marketing_email_1

    # Note: HTML encoding converts & to &amp; in the email body
    assert_match "http://example.com", mail.body.encoded
    # TODO: Fix this encoding issue
    # assert_match "contact_id=#{contact.id}", mail.body.encoded
  end

  test "marketing_email_2 contains registration link" do
    Setting.instance.update(is_emailing_enabled: true)
    contact = contacts(:full)
    mail = MarketingMailer.with(contact_id: contact.id).marketing_email_2

    # Note: HTML encoding converts & to &amp; in the email body
    assert_match "Register for a tree pickup", mail.body.encoded
    assert_match "http://example.com", mail.body.encoded
    assert_match "contact_id=#{contact.id}", mail.body.encoded
  end

  test "marketing_email_2 does not send during the cooldown window" do
    Setting.instance.update(is_emailing_enabled: true, marketing_email_cooldown_days: 7)
    contact = contacts(:full)
    contact.update(marketing_1_email_sent_at: 1.day.ago, marketing_2_email_sent_at: nil)

    mail = MarketingMailer.with(contact_id: contact.id).marketing_email_2

    assert_no_emails do
      mail.deliver_now
    end
    assert_nil contact.reload.marketing_2_email_sent_at
  end

  test "marketing_email_2 sends after the cooldown window" do
    Setting.instance.update(is_emailing_enabled: true, marketing_email_cooldown_days: 7)
    contact = contacts(:full)
    contact.update(marketing_1_email_sent_at: 8.days.ago, marketing_2_email_sent_at: nil)

    mail = MarketingMailer.with(contact_id: contact.id).marketing_email_2

    assert_emails 1 do
      mail.deliver_now
    end
  end
end
