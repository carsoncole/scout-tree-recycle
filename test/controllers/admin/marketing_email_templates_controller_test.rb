require "test_helper"

class Admin::MarketingEmailTemplatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in
    @template = marketing_email_templates(:marketing_email_1)
  end

  test "should get index" do
    get admin_marketing_email_templates_url

    assert_response :success
    assert_includes response.body, @template.display_name
  end

  test "should get new" do
    get new_admin_marketing_email_template_url

    assert_response :success
  end

  test "should get edit" do
    image = MarketingEmailTemplate.available_images.first
    image_variable = MarketingEmailTemplate.image_variable_for(image)

    get edit_admin_marketing_email_template_url(@template)

    assert_response :success
    assert_includes response.body, "Available variables"
    assert_includes response.body, "Email template preview"
    assert_includes response.body, image_variable
  end

  test "should create a draft template" do
    assert_difference -> { MarketingEmailTemplate.count }, 1 do
      post admin_marketing_email_templates_url, params: {
        marketing_email_template: {
          name: "spring_follow_up",
          description: "A follow-up email",
          subject: "Hello {{ contact.first_name }}",
          body_html: "<p>Hello {{ contact.name }}</p>",
          body_text: "Hello {{ contact.name }}"
        }
      }
    end

    template = MarketingEmailTemplate.find_by!(name: "spring_follow_up")
    assert_redirected_to edit_admin_marketing_email_template_url(template)
    assert_not template.published?
  end

  test "should not create a template with invalid liquid" do
    assert_no_difference -> { MarketingEmailTemplate.count } do
      post admin_marketing_email_templates_url, params: {
        marketing_email_template: {
          name: "broken",
          subject: "Broken",
          body_html: "{% if contact.has_name %}"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should update the draft without changing the published version" do
    published_body = @template.published_body_html

    patch admin_marketing_email_template_url(@template), params: {
      marketing_email_template: {
        subject: "Updated subject",
        body_html: "<p>Updated body</p>"
      }
    }

    assert_redirected_to edit_admin_marketing_email_template_url(@template)
    assert_equal "Updated subject", @template.reload.subject
    assert_equal published_body, @template.published_body_html
    assert @template.draft_changes?
  end

  test "should preview with contact data and inlined css" do
    get preview_admin_marketing_email_template_url(@template, contact_id: contacts(:full).id, source: "draft")

    assert_response :success
    assert_includes response.body, "Hi Susan Banks!"
    assert_includes response.body, "color: #123456"
  end

  test "should preview with sample data for an invalid contact id" do
    get preview_admin_marketing_email_template_url(@template, contact_id: "not-a-uuid", source: "draft")

    assert_response :success
    assert_includes response.body, "Susan Banks"
  end

  test "should publish a template" do
    @template.update!(subject: "Ready to go", body_html: "<p>Ready</p>")

    patch publish_admin_marketing_email_template_url(@template)

    assert_redirected_to edit_admin_marketing_email_template_url(@template)
    @template.reload
    assert @template.published?
    assert_equal "Ready to go", @template.published_subject
    assert_equal "<p>Ready</p>", @template.published_body_html
  end

  test "should unpublish a template" do
    patch unpublish_admin_marketing_email_template_url(@template)

    assert_redirected_to edit_admin_marketing_email_template_url(@template)
    assert_not @template.reload.published?
  end

  test "should restore default content as a draft" do
    published_body = @template.published_body_html
    @template.update!(body_html: "<p>Custom body</p>")

    post restore_default_admin_marketing_email_template_url(@template)

    assert_redirected_to edit_admin_marketing_email_template_url(@template)
    @template.reload
    assert_includes @template.body_html, "email-wrapper"
    assert_equal published_body, @template.published_body_html
  end

  test "should load default templates" do
    MarketingEmailTemplate.where(name: MarketingEmailTemplate.default_names).delete_all

    assert_difference -> { MarketingEmailTemplate.count }, 2 do
      post install_defaults_admin_marketing_email_templates_url
    end

    assert_redirected_to admin_marketing_email_templates_url
    assert MarketingEmailTemplate.published.exists?(name: "marketing_email_1")
    assert MarketingEmailTemplate.published.exists?(name: "marketing_email_2")
  end

  test "should send a test email using the draft" do
    configure_email!
    original_perform_deliveries = ActionMailer::Base.perform_deliveries
    ActionMailer::Base.perform_deliveries = false

    post send_test_admin_marketing_email_template_url(@template), params: {
      email: "admin@example.com",
      contact_id: contacts(:full).id,
      source: "draft"
    }

    assert_redirected_to edit_admin_marketing_email_template_url(@template)
    assert_equal "Test email sent to admin@example.com.", flash[:notice]
  ensure
    ActionMailer::Base.perform_deliveries = original_perform_deliveries
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.smtp_settings = {}
  end

  test "does not send a test email when email settings are incomplete" do
    configure_email!
    Setting.instance.update!(email_from_address: nil)

    assert_no_emails do
      post send_test_admin_marketing_email_template_url(@template), params: {
        email: "admin@example.com",
        contact_id: contacts(:full).id,
        source: "draft"
      }
    end

    assert_redirected_to edit_admin_marketing_email_template_url(@template)
    assert_equal Setting.instance.email_configuration_alert(purpose: "sending a test email"), flash[:alert]
  end

  test "should not delete default templates" do
    assert_no_difference -> { MarketingEmailTemplate.count } do
      delete admin_marketing_email_template_url(@template)
    end

    assert_redirected_to admin_marketing_email_templates_url
    assert_equal "Default templates cannot be deleted. Restore the default content instead.", flash[:alert]
  end

  test "should delete custom templates" do
    template = marketing_email_templates(:draft_template)

    assert_difference -> { MarketingEmailTemplate.count }, -1 do
      delete admin_marketing_email_template_url(template)
    end

    assert_redirected_to admin_marketing_email_templates_url
  end
end
