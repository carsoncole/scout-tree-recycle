require "test_helper"

class SendMarketingEmail1JobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    configure_email!
  end

  test "enqueues an email for each contact that has not received marketing email 1" do
    assert_enqueued_emails Contact.marketing_subscribed.where(marketing_1_email_sent_at: nil).count do
      SendMarketingEmail1Job.perform_now
    end
  end

  test "does not enqueue emails for unsubscribed contacts" do
    Contact.marketing_subscribed.update_all(is_unsubscribed_from_marketing: true)

    assert_no_enqueued_emails do
      SendMarketingEmail1Job.perform_now
    end
  end

  test "respects the configured batch quantity" do
    Setting.instance.update(email_batch_quantity: 1)

    assert_enqueued_emails 1 do
      SendMarketingEmail1Job.perform_now
    end
  end

  test "does not enqueue emails when emailing is disabled" do
    Setting.instance.update(is_emailing_enabled: false)

    assert_no_enqueued_emails do
      SendMarketingEmail1Job.perform_now
    end
  end

  test "does not enqueue emails when email settings are incomplete" do
    Setting.instance.update!(smtp_address: nil)

    assert_no_enqueued_emails do
      SendMarketingEmail1Job.perform_now
    end
  end

  test "does not enqueue emails when the template is not published" do
    marketing_email_templates(:marketing_email_1).unpublish!

    assert_no_enqueued_emails do
      SendMarketingEmail1Job.perform_now
    end
  end
end
