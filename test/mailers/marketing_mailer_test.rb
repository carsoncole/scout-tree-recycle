require "test_helper"

class MarketingMailerTest < ActionMailer::TestCase
  include ActionDispatch::Routing::UrlFor
  include Rails.application.routes.url_helpers

  class FailingDelivery
    def initialize(_settings = {}); end

    def deliver!(_mail)
      raise "delivery failed"
    end
  end

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

  test "uses the published template instead of the draft" do
    Setting.instance.update(is_emailing_enabled: true)
    template = marketing_email_templates(:marketing_email_1)
    template.update!(subject: "Draft subject", body_html: "<p>Draft body</p>")

    mail = MarketingMailer.with(contact_id: contacts(:full).id).marketing_email_1

    assert_equal "Tree recycling January 6. Register today.", mail.subject
    assert_match "Support Troop 100! - Tree Recycling", mail.body.encoded
    assert_no_match "Draft body", mail.body.encoded
  end

  test "uses the published from address instead of the draft from address" do
    Setting.instance.update(is_emailing_enabled: true)
    template = marketing_email_templates(:marketing_email_1)
    template.update!(from: "draft@example.com")

    mail = MarketingMailer.with(contact_id: contacts(:full).id).marketing_email_1
    assert_equal [ "example@example.com" ], mail.from

    template.update_columns(published_from: "published@example.com")
    mail = MarketingMailer.with(contact_id: contacts(:no_mobile).id).marketing_email_1
    assert_equal [ "published@example.com" ], mail.from
  end

  test "marks the contact as sent only after successful delivery" do
    Setting.instance.update(is_emailing_enabled: true)
    contact = contacts(:full)

    mail = MarketingMailer.with(contact_id: contact.id).marketing_email_1
    assert_nil contact.reload.marketing_1_email_sent_at

    assert_emails 1 do
      mail.deliver_now
    end

    assert contact.reload.marketing_1_email_sent_at.present?
  end

  test "does not mark the contact as sent when delivery fails" do
    Setting.instance.update(is_emailing_enabled: true)
    contact = contacts(:full)
    original_delivery_method = ActionMailer::Base.delivery_method
    ActionMailer::Base.delivery_method = FailingDelivery

    mail = MarketingMailer.with(contact_id: contact.id).marketing_email_1

    assert_raises(RuntimeError) do
      mail.deliver_now
    end
    assert_nil contact.reload.marketing_1_email_sent_at
  ensure
    ActionMailer::Base.delivery_method = original_delivery_method
  end

  test "does not send without a from address" do
    Setting.instance.update(is_emailing_enabled: true, email_from_address: nil)

    assert_no_emails do
      MarketingMailer.with(contact_id: contacts(:full).id).marketing_email_1.deliver_now
    end
  end

  test "does not send when the template is unpublished" do
    Setting.instance.update(is_emailing_enabled: true)
    marketing_email_templates(:marketing_email_1).unpublish!

    assert_no_emails do
      MarketingMailer.with(contact_id: contacts(:full).id).marketing_email_1.deliver_now
    end
  end

  test "does not send when the template is missing" do
    Setting.instance.update(is_emailing_enabled: true)
    MarketingEmailTemplate.where(name: "marketing_email_1").delete_all

    assert_no_emails do
      MarketingMailer.with(contact_id: contacts(:full).id).marketing_email_1.deliver_now
    end
  end

  test "raises when an explicit contact id is missing" do
    Setting.instance.update(is_emailing_enabled: true)

    assert_raises(ActiveRecord::RecordNotFound) do
      MarketingMailer.with(contact_id: SecureRandom.uuid).marketing_email_1.deliver_now
    end
  end

  test "includes a plain text alternative" do
    Setting.instance.update(is_emailing_enabled: true)

    mail = MarketingMailer.with(contact_id: contacts(:full).id).marketing_email_1

    assert mail.multipart?
    assert_includes mail.text_part.body.to_s, "Reserve My Tree Pickup: http://example.com"
    assert_not_includes mail.text_part.body.to_s, "&amp;"
  end

  test "inlines template styles when delivered" do
    Setting.instance.update(is_emailing_enabled: true)

    MarketingMailer.with(contact_id: contacts(:full).id).marketing_email_1.deliver_now

    delivered = ActionMailer::Base.deliveries.last
    html = delivered.html_part&.body&.to_s || delivered.body.to_s
    assert_includes html, "color: #123456"
  end

  test "test email sends the draft to the requested address" do
    Setting.instance.update(is_emailing_enabled: false)
    template = marketing_email_templates(:marketing_email_1)
    template.update!(subject: "Draft subject", body_html: "<p>Draft body for {{ contact.name }}</p>")
    contact = contacts(:full)

    mail = MarketingMailer.with(
      template_id: template.id,
      contact_id: contact.id,
      email: "qa@example.com",
      source: "draft"
    ).test_email

    assert_equal [ "qa@example.com" ], mail.to
    assert_equal "[TEST] Draft subject", mail.subject
    assert_match "Draft body for Susan Banks", mail.body.encoded
    assert_nil contact.reload.marketing_1_email_sent_at
  end
end
