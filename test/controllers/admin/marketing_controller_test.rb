require "test_helper"

class Admin::MarketingControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    sign_in
    get admin_marketing_index_url
    assert_response :success
    assert_select "input[type='email'][value=?]", users(:admin).email, count: 2
    assert_select "#delete-all-contacts", count: 1
    assert_select "#delete-all-contacts form[action=?]", destroy_all_admin_contacts_path
  end

  test "user can use marketing except delete all contacts" do
    sign_in(users(:user))
    get admin_marketing_index_url
    assert_response :success
    assert_select "#delete-all-contacts", text: /Delete all contacts/
    assert_select "#delete-all-contacts", text: /Admin only/
    assert_select "#delete-all-contacts", text: /Only admins can delete all contacts/
    assert_select "#delete-all-contacts form", count: 0
    assert_select "a[href=?]", edit_admin_contact_path(contacts(:full))
    assert_select "form[action=?]", admin_send_marketing_email_1_path
  end

  test "should get index with disabled emailing" do
    Setting.instance.update(is_emailing_enabled: false)
    sign_in
    get admin_marketing_index_url
    assert_nil flash[:alert]
    assert_select "form[action=?] button[disabled]", admin_send_marketing_email_1_path, count: 1
    assert_select "form[action=?] button[disabled]", admin_send_marketing_email_2_path, count: 1
    assert_select "a[href=?]", admin_settings_section_path("email"), text: "Settings"
    assert_select "p", /Marketing emailing is disabled.*enable marketing emailing in/i
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
    assert_select "a[href=?]", admin_settings_section_path("email"), text: "Edit in Settings", count: 2
  end

  test "index asks for confirmation with the number of emails before sending" do
    Setting.instance.update!(is_emailing_enabled: true, email_batch_quantity: 2)
    sign_in

    get admin_marketing_index_url

    assert_response :success
    assert_select "form[action=?] button:not([disabled])[data-turbo-confirm=?]",
      admin_send_marketing_email_1_path,
      "Send Marketing Email 1 to 2 contacts? Contacts who already received it will be skipped. This cannot be undone.",
      count: 1
    assert_select "form[action=?] button:not([disabled])[data-turbo-confirm=?]",
      admin_send_marketing_email_2_path,
      "Send Marketing Email 2 to 2 contacts? Contacts who already received it will be skipped. This cannot be undone.",
      count: 1
  end

  test "index offers a send test email form for each marketing email" do
    sign_in

    get admin_marketing_index_url

    assert_response :success
    assert_select "form[action=?]", admin_send_marketing_email_test_path, count: 2
    assert_select "input[type=hidden][name=template_name][value=?]", "marketing_email_1", count: 1
    assert_select "input[type=hidden][name=template_name][value=?]", "marketing_email_2", count: 1
  end

  test "sends a test marketing email to the requested address" do
    configure_email!
    sign_in
    original_perform_deliveries = ActionMailer::Base.perform_deliveries
    ActionMailer::Base.perform_deliveries = false

    post admin_send_marketing_email_test_url, params: {
      template_name: "marketing_email_1",
      email: "qa@example.com",
      contact_id: contacts(:full).id
    }

    assert_redirected_to admin_marketing_index_url
    assert_equal "Test email sent to qa@example.com.", flash[:notice]
    assert_nil contacts(:full).reload.marketing_1_email_sent_at
  ensure
    ActionMailer::Base.perform_deliveries = original_perform_deliveries
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.smtp_settings = {}
  end

  test "does not send a test marketing email without a recipient" do
    configure_email!
    sign_in

    assert_no_emails do
      post admin_send_marketing_email_test_url, params: {
        template_name: "marketing_email_1",
        email: " "
      }
    end

    assert_redirected_to admin_marketing_index_url
    assert_equal "Enter an email address for the test message.", flash[:alert]
  end

  test "does not send a test marketing email when the template is unpublished" do
    configure_email!
    marketing_email_templates(:marketing_email_1).unpublish!
    sign_in

    assert_no_emails do
      post admin_send_marketing_email_test_url, params: {
        template_name: "marketing_email_1",
        email: "qa@example.com"
      }
    end

    assert_redirected_to admin_marketing_index_url
    assert_equal "Marketing email 1 is not published. Edit the template and publish it before sending a test.", flash[:alert]
  end

  test "does not send a test marketing email for an unknown template" do
    configure_email!
    sign_in

    assert_no_emails do
      post admin_send_marketing_email_test_url, params: {
        template_name: "weekly_reminder",
        email: "qa@example.com"
      }
    end

    assert_redirected_to admin_marketing_index_url
    assert_equal "Choose a marketing email before sending a test.", flash[:alert]
  end

  test "does not send a test marketing email when email settings are incomplete" do
    configure_email!
    Setting.instance.update!(email_from_address: nil)
    sign_in

    assert_no_emails do
      post admin_send_marketing_email_test_url, params: {
        template_name: "marketing_email_1",
        email: "qa@example.com"
      }
    end

    assert_redirected_to admin_marketing_index_url
    assert_equal Setting.instance.email_configuration_alert(purpose: "sending a test email"), flash[:alert]
  end

  test "should send marketing email 1" do
    sign_in
    configure_email!
    post admin_send_marketing_email_1_url
    assert_redirected_to admin_marketing_index_url
    count_to_be_sent = Contact.marketing_subscribed.where(marketing_1_email_sent_at: nil).count
    queued_count = [ Setting.instance.email_batch_quantity, count_to_be_sent ].min
    assert_equal "#{queued_count} of #{count_to_be_sent} marketing #1 emails queued to be sent.", flash[:notice]
  end

  test "should send marketing email 2" do
    configure_email!
    sign_in
    post admin_send_marketing_email_2_url
    assert_redirected_to admin_marketing_index_url
    count_to_be_sent = Contact.marketing_subscribed.where(marketing_2_email_sent_at: nil).count
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

  test "does not queue marketing email 1 when remaining contacts are unsubscribed" do
    configure_email!
    Contact.update_all(marketing_1_email_sent_at: Time.current)
    contact = Contact.create!(name: "Unsubscribed", email: "unsubscribed@example.com", is_unsubscribed_from_marketing: true)
    sign_in

    assert_no_enqueued_jobs only: SendMarketingEmail1Job do
      post admin_send_marketing_email_1_url
    end

    assert_redirected_to admin_marketing_index_url
    assert_equal "No contacts are eligible for Marketing email 1.", flash[:alert]
    assert contact.persisted?
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

  test "should search contacts by name, email, or street" do
    sign_in
    get admin_marketing_index_url(q: "Susan")
    assert_response :success
    assert_select "table.admin-table tbody tr", count: 1
    assert_select "table.admin-table tbody td", text: "Susan Banks"
    assert_select "table.admin-table tbody td", text: "Bob Jones", count: 0
    assert_select "input[name=?][value=?]", "q", "Susan"
  end

  test "search with no matches shows empty state" do
    sign_in
    get admin_marketing_index_url(q: "no-such-contact")
    assert_response :success
    assert_select "p", text: "No contacts are available for marketing."
  end
end
