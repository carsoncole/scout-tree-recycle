require "application_system_test_case"

class Admin::ReservationEmailTemplatesTest < ApplicationSystemTestCase
  setup do
    sign_in_as(users(:admin), true)
  end

  test "editing and publishing a reservation email template" do
    template = reservation_email_templates(:new_reservation_email)
    published_subject = template.published_subject

    visit admin_marketing_index_url
    click_on "Reservation Emails"

    assert_selector "summary", text: "Send test email", count: 3

    within "section", text: "New reservation email" do
      click_on "Edit Template"
    end

    assert_selector "h1", text: "Edit New Reservation Email"
    assert_selector "h2", text: "Top logo"
    assert_selector "h2", text: "Available variables"
    assert_field "Subject", with: template.subject

    fill_in "Subject", with: "A brand new reservation subject"
    fill_in "reservation_email_template[body_html]", with: "<p>Custom body for {{ reservation.name }}</p>"
    click_on "Save Draft"

    assert_text "Reservation email template was saved as a draft."
    template.reload
    assert_equal "A brand new reservation subject", template.subject
    assert_equal published_subject, template.published_subject

    click_on "Publish Template"

    assert_text "Template published."
    template.reload
    assert template.published?
    assert_equal "A brand new reservation subject", template.published_subject
    assert_equal "<p>Custom body for {{ reservation.name }}</p>", template.published_body_html
  end
end
