require "test_helper"

class Admin::MarketingControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    sign_in
    get admin_marketing_index_url
    assert_response :success
  end

  test "should get index with disabled emailing" do
    Setting.instance.update(is_emailing_enabled: false)
    sign_in
    get admin_marketing_index_url
    assert_equal "Emailing is disabled. Enable email notifications in Settings to send marketing emails.", flash[:alert]
  end

  test "should get index with incomplete email settings" do
    configure_email!
    Setting.instance.update!(smtp_address: nil)
    sign_in

    get admin_marketing_index_url

    assert_response :success
    assert_equal Setting.instance.email_configuration_alert(purpose: "sending marketing emails"), flash[:alert]
  end

  test "index shows the email batch size with a link to edit it in settings" do
    Setting.instance.update!(email_batch_quantity: 42)
    sign_in

    get admin_marketing_index_url

    assert_response :success
    assert_select "p", text: /Batch size: 42 contacts per send/, count: 2
    assert_select "a[href=?]", admin_settings_path(anchor: "email"), text: "Edit in Settings", count: 2
  end

  test "should send marketing email 1" do
    sign_in
    configure_email!
    post admin_send_marketing_email_1_url
    assert_redirected_to admin_marketing_index_url
    count_to_be_sent = Contact.where(marketing_1_email_sent_at: nil).count
    queued_count = [ Setting.instance.email_batch_quantity, count_to_be_sent ].min
    assert_equal "#{queued_count} of #{count_to_be_sent} marketing #1 emails queued to be sent.", flash[:notice]
  end

  test "should send marketing email 2" do
    configure_email!
    sign_in
    post admin_send_marketing_email_2_url
    assert_redirected_to admin_marketing_index_url
    count_to_be_sent = Contact.where(marketing_2_email_sent_at: nil).count
    queued_count = [ Setting.instance.email_batch_quantity, count_to_be_sent ].min
    assert_equal "#{queued_count} of #{count_to_be_sent} marketing #2 emails queued to be sent.", flash[:notice]
  end

  test "does not queue marketing email 1 when no contacts are eligible" do
    configure_email!
    Contact.update_all(marketing_1_email_sent_at: Time.current)
    sign_in

    assert_no_enqueued_jobs only: SendMarketingEmail1Job do
      post admin_send_marketing_email_1_url
    end

    assert_redirected_to admin_marketing_index_url
    assert_equal "No contacts are eligible for Marketing email 1.", flash[:alert]
  end

  test "does not queue marketing email 2 when no contacts are eligible" do
    configure_email!
    Contact.update_all(marketing_2_email_sent_at: Time.current)
    sign_in

    assert_no_enqueued_jobs only: SendMarketingEmail2Job do
      post admin_send_marketing_email_2_url
    end

    assert_redirected_to admin_marketing_index_url
    assert_equal "No contacts are eligible for Marketing email 2.", flash[:alert]
  end

  test "does not send marketing email 1 when email settings are incomplete" do
    configure_email!
    Setting.instance.update!(email_from_address: nil)
    sign_in

    assert_no_enqueued_jobs only: SendMarketingEmail1Job do
      post admin_send_marketing_email_1_url
    end

    assert_redirected_to admin_marketing_index_url
    assert_equal Setting.instance.email_configuration_alert(purpose: "sending marketing emails"), flash[:alert]
  end

  test "does not send marketing email 2 when email settings are incomplete" do
    configure_email!
    Setting.instance.update!(smtp_port: nil)
    sign_in

    assert_no_enqueued_jobs only: SendMarketingEmail2Job do
      post admin_send_marketing_email_2_url
    end

    assert_redirected_to admin_marketing_index_url
    assert_equal Setting.instance.email_configuration_alert(purpose: "sending marketing emails"), flash[:alert]
  end

  test "does not send marketing email 1 when the template is unpublished" do
    configure_email!
    marketing_email_templates(:marketing_email_1).unpublish!
    sign_in

    assert_no_enqueued_jobs only: SendMarketingEmail1Job do
      post admin_send_marketing_email_1_url
    end

    assert_redirected_to admin_marketing_index_url
    assert_equal "Marketing email 1 is not published. Edit the template and publish it before sending.", flash[:alert]
  end

  test "does not send marketing email 2 when the template is unpublished" do
    configure_email!
    marketing_email_templates(:marketing_email_2).unpublish!
    sign_in

    assert_no_enqueued_jobs only: SendMarketingEmail2Job do
      post admin_send_marketing_email_2_url
    end

    assert_redirected_to admin_marketing_index_url
    assert_equal "Marketing email 2 is not published. Edit the template and publish it before sending.", flash[:alert]
  end
end
