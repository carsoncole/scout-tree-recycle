require "test_helper"

class SendMarketingEmail2JobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    configure_email!
  end

  test "enqueues an email for each contact that has not received marketing email 2" do
    assert_enqueued_emails Contact.where(marketing_2_email_sent_at: nil).count do
      SendMarketingEmail2Job.perform_now
    end
  end

  test "respects the configured batch quantity" do
    Setting.instance.update(email_batch_quantity: 1)

    assert_enqueued_emails 1 do
      SendMarketingEmail2Job.perform_now
    end
  end

  test "does not enqueue emails when emailing is disabled" do
    Setting.instance.update(is_emailing_enabled: false)

    assert_no_enqueued_emails do
      SendMarketingEmail2Job.perform_now
    end
  end

  test "does not enqueue emails when email settings are incomplete" do
    Setting.instance.update!(email_from_address: nil)

    assert_no_enqueued_emails do
      SendMarketingEmail2Job.perform_now
    end
  end

  test "does not enqueue emails when the template is not published" do
    marketing_email_templates(:marketing_email_2).unpublish!

    assert_no_enqueued_emails do
      SendMarketingEmail2Job.perform_now
    end
  end
end
