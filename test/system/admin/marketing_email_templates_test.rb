require "application_system_test_case"

class Admin::MarketingEmailTemplatesTest < ApplicationSystemTestCase
  setup do
    sign_in_as(users(:admin), true)
  end

  test "editing a template from the marketing page saves a draft" do
    template = marketing_email_templates(:marketing_email_1)
    published_subject = template.published_subject

    visit admin_marketing_index_url
    within "section", text: "Marketing email 1" do
      click_on "Edit Template"
    end

    assert_selector "h1", text: "Edit Marketing Email 1"
    assert_text "Unsubscribe is added automatically."
    assert_selector "h2", text: "Available variables"
    assert_field "Subject", with: template.subject

    fill_in "Subject", with: "A brand new subject"
    click_on "Save Draft"

    assert_text "Email template was saved as a draft. Publish it to make the changes live."
    template.reload
    assert_equal "A brand new subject", template.subject
    assert_equal published_subject, template.published_subject
  end

  test "changing the preview contact keeps unsaved edits" do
    contact = contacts(:name_and_email)

    visit edit_admin_marketing_email_template_url(marketing_email_templates(:marketing_email_1))
    fill_in "Subject", with: "Unsaved subject"

    select "Bob Jones <bob.jones@example.com>", from: "Preview with contact"

    assert_selector "iframe.admin-preview-frame[src*='#{contact.id}']"
    assert_field "Subject", with: "Unsaved subject"
  end

  test "previewing a template with contact data" do
    visit preview_admin_marketing_email_template_url(
      marketing_email_templates(:marketing_email_1),
      contact_id: contacts(:full).id,
      source: "draft"
    )

    assert_text "Hi Susan Banks!"
    assert_text "Registration is now open for Tuesday, January 6."
  end

  test "publishing a template" do
    template = marketing_email_templates(:marketing_email_1)
    template.update!(subject: "Ready to publish")

    visit edit_admin_marketing_email_template_url(template)
    click_on "Publish Template"

    assert_text "Template published. New marketing emails will use this version."
    assert_equal "Ready to publish", template.reload.published_subject
  end

  test "loading default templates from the index" do
    MarketingEmailTemplate.where(name: MarketingEmailTemplate.default_names).delete_all

    visit admin_marketing_email_templates_url
    accept_confirm do
      click_on "Load Default Templates"
    end

    assert_text "Default templates were loaded."
    assert_equal 2, MarketingEmailTemplate.where(name: MarketingEmailTemplate.default_names).count
  end
end
