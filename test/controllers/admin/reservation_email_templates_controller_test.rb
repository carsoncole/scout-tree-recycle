require "test_helper"

class Admin::ReservationEmailTemplatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in
    @template = reservation_email_templates(:new_reservation_email)
    @reservation = reservations(:pending_pickup_1)
  end

  test "should get index" do
    get admin_reservation_email_templates_url

    assert_response :success
    assert_includes response.body, "New reservation email"
    assert_includes response.body, "Cancelled reservation email"
    assert_includes response.body, "Missing tree email"
    assert_includes response.body, "Send test email"
    assert_includes response.body, "Send the follow-up version"
    assert_includes response.body, "Use reservation data from"
    assert_select "input[type='email'][value=?]", users(:admin).email, count: ReservationEmailTemplate::NAMES.size
  end

  test "should get edit" do
    image_variable = EmailImageLibrary.image_variable_for(EmailImageLibrary.available_images.first)

    get edit_admin_reservation_email_template_url(@template)

    assert_response :success
    assert_includes response.body, "Available variables"
    assert_includes response.body, "Reservation email template preview"
    assert_includes response.body, "Top logo"
    assert_includes response.body, image_variable
    assert_includes response.body, "Preview with reservation"
  end

  test "should update the draft without changing the published version" do
    published_body = @template.published_body_html

    patch admin_reservation_email_template_url(@template), params: {
      reservation_email_template: {
        subject: "Updated subject",
          body_html: "<p>Updated body for {{ reservation.name }}</p>"
      }
    }

    assert_redirected_to edit_admin_reservation_email_template_url(@template)
    @template.reload
    assert_equal "Updated subject", @template.subject
    assert_equal published_body, @template.published_body_html
    assert @template.draft_changes?
  end

  test "should not update with invalid liquid" do
    patch admin_reservation_email_template_url(@template), params: {
      reservation_email_template: {
        body_html: "{% if reservation.has_name %}"
      }
    }

    assert_response :unprocessable_entity
    assert_match "Liquid syntax error", response.body
  end

  test "should preview the draft with reservation data and inlined css" do
    get preview_admin_reservation_email_template_url(@template, reservation_id: @reservation.id, source: "draft")

    assert_response :success
    assert_includes response.body, "Dear Mary Jones"
    assert_includes response.body, "color: #123456"
    assert_includes response.body, "data:image/png;base64,"
    assert_includes response.body, %(width="#{ReservationEmailTemplate::LOGO_WIDTH}")
    assert_includes response.body, "/reservations/#{@reservation.public_token}/edit"
  end

  test "should preview the published version separately from the draft" do
    @template.update!(body_html: "<p>Draft only body</p>")

    get preview_admin_reservation_email_template_url(@template, reservation_id: @reservation.id, source: "published")

    assert_response :success
    assert_includes response.body, "Tree pick-up scheduled"
    assert_not_includes response.body, "Draft only body"
  end

  test "should preview with sample data for an invalid reservation id" do
    get preview_admin_reservation_email_template_url(@template, reservation_id: "not-a-uuid", source: "draft")

    assert_response :success
    assert_includes response.body, "Susan Banks"
  end

  test "should preview the missing tree follow-up version" do
    template = reservation_email_templates(:missing_tree_email)

    get preview_admin_reservation_email_template_url(template, reservation_id: @reservation.id, source: "draft", follow_up: "1")

    assert_response :success
    assert_includes response.body, "We visited again today"
  end

  test "should publish a template" do
    @template.update!(subject: "Ready to go", body_html: "<p>Ready</p>", logo_alt: "Ready logo")

    patch publish_admin_reservation_email_template_url(@template)

    assert_redirected_to edit_admin_reservation_email_template_url(@template)
    @template.reload
    assert @template.published?
    assert_equal "Ready to go", @template.published_subject
    assert_equal "<p>Ready</p>", @template.published_body_html
  end

  test "should unpublish a template" do
    patch unpublish_admin_reservation_email_template_url(@template)

    assert_redirected_to edit_admin_reservation_email_template_url(@template)
    assert_not @template.reload.published?
  end

  test "should restore default content as a draft" do
    published_body = @template.published_body_html
    @template.update!(body_html: "<p>Custom body</p>")

    post restore_default_admin_reservation_email_template_url(@template)

    assert_redirected_to edit_admin_reservation_email_template_url(@template)
    @template.reload
    assert_includes @template.body_html, "email-heading"
    assert_equal published_body, @template.published_body_html
  end

  test "should load default templates" do
    ReservationEmailTemplate.delete_all

    assert_difference -> { ReservationEmailTemplate.count }, ReservationEmailTemplate::NAMES.size do
      post install_defaults_admin_reservation_email_templates_url
    end

    assert_redirected_to admin_reservation_email_templates_url
    assert ReservationEmailTemplate.published.exists?(name: "new_reservation_email")
    assert ReservationEmailTemplate.published.exists?(name: "cancelled_reservation_email")
    assert ReservationEmailTemplate.published.exists?(name: "missing_tree_email")
    assert ReservationEmailTemplate.published.exists?(name: "pickup_reminder_email")
  end

  test "should send a test email using the draft" do
    configure_email!
    original_perform_deliveries = ActionMailer::Base.perform_deliveries
    ActionMailer::Base.perform_deliveries = false

    post send_test_admin_reservation_email_template_url(@template), params: {
      email: "admin@example.com",
      reservation_id: @reservation.id,
      source: "draft",
      follow_up: "0"
    }

    assert_redirected_to edit_admin_reservation_email_template_url(@template)
    assert_equal "Test email sent to admin@example.com.", flash[:notice]
  ensure
    ActionMailer::Base.perform_deliveries = original_perform_deliveries
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.smtp_settings = {}
  end

  test "should send a published test email from the index" do
    configure_email!
    original_perform_deliveries = ActionMailer::Base.perform_deliveries
    ActionMailer::Base.perform_deliveries = false

    post send_test_admin_reservation_email_template_url(@template), params: {
      email: "admin@example.com",
      reservation_id: @reservation.id,
      source: "published",
      return_to: "index"
    }

    assert_redirected_to admin_reservation_email_templates_url
    assert_equal "Test email sent to admin@example.com.", flash[:notice]
  ensure
    ActionMailer::Base.perform_deliveries = original_perform_deliveries
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.smtp_settings = {}
  end

  test "does not send a published test email when the template is unpublished" do
    configure_email!
    @template.update!(published_at: nil)

    assert_no_emails do
      post send_test_admin_reservation_email_template_url(@template), params: {
        email: "admin@example.com",
        reservation_id: @reservation.id,
        source: "published",
        return_to: "index"
      }
    end

    assert_redirected_to admin_reservation_email_templates_url
    assert_match "not been published", flash[:alert]
  end

  test "does not send a test email when email settings are incomplete" do
    configure_email!
    Setting.instance.update!(email_from_address: nil)

    assert_no_emails do
      post send_test_admin_reservation_email_template_url(@template), params: {
        email: "admin@example.com",
        reservation_id: @reservation.id,
        source: "draft"
      }
    end

    assert_redirected_to edit_admin_reservation_email_template_url(@template)
    assert_equal Setting.instance.email_configuration_alert(purpose: "sending a test email"), flash[:alert]
  end
end
