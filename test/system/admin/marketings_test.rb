require "application_system_test_case"

class Admin::MarketingsTest < ApplicationSystemTestCase
  setup do
    sign_in_as(users(:admin), true)
  end

  test "visiting the index" do
    visit admin_marketing_index_url

    assert_selector "h1", text: "Marketing"
  end

  test "index explains that marketing emails are only sent once per contact" do
    visit admin_marketing_index_url

    assert_text "Sent only once per contact. Contacts who already received Marketing email 1 are skipped"
    assert_text "Sent only once per contact. Contacts who already received Marketing email 2 are skipped"
  end

  test "index shows the email batch size with a link to settings" do
    Setting.instance.update!(email_batch_quantity: 42)

    visit admin_marketing_index_url

    assert_text "Batch size: 42 contacts per send.", count: 2

    within "section", text: "Marketing email 1" do
      click_on "Edit in Settings"
    end

    assert_current_path admin_settings_section_path("email")
    assert_selector "section#email", text: "Email"
  end

  test "confirms the number of contacts before sending a marketing email" do
    configure_email!

    visit admin_marketing_index_url

    within "section", text: "Marketing email 2" do
      message = dismiss_confirm { click_on "Send Marketing Email 2" }

      assert_equal "Send Marketing Email 2 to 3 contacts? Contacts who already received it will be skipped. This cannot be undone.", message
    end

    assert_current_path admin_marketing_index_path
  end

  test "sending a test email from the marketing page" do
    configure_email!
    original_perform_deliveries = ActionMailer::Base.perform_deliveries
    ActionMailer::Base.perform_deliveries = false

    visit admin_marketing_index_url

    within "section", text: "Marketing email 1" do
      find("summary", text: "Send test email").click
      fill_in "Send to", with: "qa@example.com"
      click_on "Send Test Email"
    end

    assert_text "Test email sent to qa@example.com."
  ensure
    ActionMailer::Base.perform_deliveries = original_perform_deliveries
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.smtp_settings = {}
  end

  test "viewing the available email images" do
    image = MarketingEmailTemplate.available_images.first
    variable = MarketingEmailTemplate.image_variable_for(image)

    visit admin_marketing_index_url
    click_on "View Email Images"

    assert_selector "h1", text: "Email Images"
    assert_text image
    assert_text variable
  end

  test "index notes that contacts are removed for confirmed reservations" do
    visit admin_marketing_index_url

    assert_text "Any contacts with the same email as a newly confirmed reservation are removed automatically"
  end

  test "index shows a flash when email settings are incomplete" do
    Setting.instance.update!(is_emailing_enabled: true, email_from_address: nil, smtp_address: nil, smtp_port: nil)

    visit admin_marketing_index_url

    assert_text "Email settings are incomplete."
    assert_text "Email From Address"
    assert_text "SMTP Address"
    assert_text "SMTP Port"
  end

  test "adding a contact" do
    visit admin_marketing_index_url
    click_on "New Contact"

    fill_in "Name", with: "Jordan Fields"
    fill_in "Email", with: "Jordan.Fields@example.com"
    fill_in "Mobile", with: "555-555-5555"
    fill_in "Street", with: "7 Pine Rd"
    click_on "Create Contact"

    assert_text "Contact was successfully created."
    assert_text "jordan.fields@example.com"
    assert_equal "Jordan Fields", Contact.find_by(email: "jordan.fields@example.com").name
  end

  test "editing a contact" do
    visit admin_marketing_index_url

    within "tr", text: contacts(:full).email do
      click_on "Edit"
    end

    fill_in "Name", with: "Susan B. Banks"
    click_on "Update Contact"

    assert_text "Contact was successfully updated."
    assert_text "Susan B. Banks"
  end

  test "shows the local date and time each marketing email was sent" do
    this_year = Time.zone.parse("#{Time.current.year}-01-15 09:30")
    last_year = Time.zone.parse("#{Time.current.year - 1}-03-02 14:05")
    contacts(:full).update!(marketing_1_email_sent_at: this_year, marketing_2_email_sent_at: last_year)

    visit admin_marketing_index_url

    within "tr", text: contacts(:full).email do
      assert_text "Jan 15, 9:30 AM"
      assert_text "Mar 2, #{Time.current.year - 1} 2:05 PM"
    end
  end

  test "clearing a marketing email sent date" do
    contact = contacts(:full)
    contact.update!(marketing_1_email_sent_at: 1.day.ago)

    visit admin_marketing_index_url

    within "tr", text: contact.email do
      accept_confirm { click_on "Clear Marketing email 1 sent date" }
    end

    assert_text "Marketing email 1 sent date was cleared."
    assert_nil contact.reload.marketing_1_email_sent_at

    within "tr", text: contact.email do
      assert_no_button "Clear Marketing email 1 sent date"
      assert_selector "form[action='#{send_marketing_email_1_admin_contact_path(contact)}'] button"
    end
  end

  test "sending an individual marketing email from the contacts table" do
    configure_email!
    contact = contacts(:full)
    contact.update!(marketing_1_email_sent_at: nil)

    visit admin_marketing_index_url

    within "tr", text: contact.email do
      accept_confirm do
        find("form[action='#{send_marketing_email_1_admin_contact_path(contact)}'] button").click
      end
    end

    assert_text "Marketing email 1 queued for #{contact.email}."
  end

  test "does not show send buttons for marketing emails already sent" do
    contact = contacts(:full)
    contact.update!(marketing_1_email_sent_at: Time.current, marketing_2_email_sent_at: Time.current)

    visit admin_marketing_index_url

    within "tr", text: contact.email do
      assert_no_selector "form[action='#{send_marketing_email_1_admin_contact_path(contact)}']"
      assert_no_selector "form[action='#{send_marketing_email_2_admin_contact_path(contact)}']"
    end
  end

  test "does not offer delete all contacts" do
    visit admin_marketing_index_url

    assert_no_text "Delete all contacts"
    assert_no_button "Delete All Contacts"
  end
end
