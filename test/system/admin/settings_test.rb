require "application_system_test_case"

class Admin::SettingsTest < ApplicationSystemTestCase
  setup do
    sign_in_as(users(:admin), true)
  end

  test "visiting the index" do
    visit admin_settings_url

    assert_selector "h1", text: "Settings"
  end

  test "settings sidebar links to each section" do
    visit admin_settings_url

    within "nav.admin-settings-nav" do
      assert_link "Overview", href: admin_settings_path
      assert_link "The Event", href: admin_settings_section_path("event")
      assert_link "Organization", href: admin_settings_section_path("organization")
      assert_link "Site Details", href: admin_settings_section_path("site_details")
      assert_link "Site Content", href: admin_settings_section_path("site_content")
      assert_link "Pickups Portal", href: admin_settings_section_path("pickups")
      assert_link "SMS", href: admin_settings_section_path("sms")
      assert_link "Email", href: admin_settings_section_path("email")
      assert_link "Donations", href: admin_settings_section_path("donations")
      assert_link "Location Services", href: admin_settings_section_path("location_services")
      assert_link "System", href: admin_settings_section_path("system")
      assert_no_link "Operations"
      assert_link "Users", href: admin_users_path
    end
  end

  test "each settings section has its own page" do
    Setting::SECTIONS.each do |section, metadata|
      visit admin_settings_section_path(section)

      assert_selector "h1", text: metadata[:label]
      assert_selector "nav.admin-settings-nav"
    end
  end

  test "shows configuration status and missing required settings" do
    visit admin_settings_url

    within "#configuration-status" do
      assert_text "1 missing"
      assert_link "Site URL", href: admin_settings_section_path("site_details")
    end

    Setting.instance.update(site_url: "https://example.com")
    visit admin_settings_url

    within "#configuration-status" do
      assert_text "Ready"
      assert_text "All required settings are configured."
    end
  end

  test "blank default city and state are reported as missing" do
    visit admin_settings_section_path("event")

    within "section.admin-panel", text: "The Event" do
      fill_in "Default City", with: ""
      fill_in "Default State", with: ""
      click_on "Save Settings"
    end

    assert_text "Settings were successfully updated"

    visit admin_settings_url

    within "#configuration-status" do
      assert_link "Default City", href: admin_settings_section_path("event")
      assert_link "Default State", href: admin_settings_section_path("event")
    end
  end

  test "pickups portal is disabled when not enabled" do
    Setting.instance.update(is_pickups_site_enabled: false)

    visit pickups_root_url

    assert_selector ".flash", text: "The Pickups site is CLOSED."
  end

  test "pickups portal is enabled when enabled" do
    Setting.instance.update(is_pickups_site_enabled: true)

    visit pickups_root_url

    assert_no_text "The Pickups site is CLOSED."
  end

  test "pickups portal is accessible when driver password is set" do
    Setting.instance.update(is_pickups_site_enabled: true, driver_secret_key: "1234567890")

    visit pickups_root_url
    fill_in "Password", with: "1234567890"
    click_on "Access Pickups"

    assert_selector "h1", text: "Pickups"
  end

  test "new settings page should show errors if settings are not valid" do
    Setting.destroy_all
    visit root_path
    fill_in "Organization Name", with: ""
    fill_in "Event Pickup Start", with: ""
    click_on "Save Settings"

    within("#organization_name_section") do
      assert_text "can't be blank"
    end
    within("#event_pickup_start_section") do
      assert_text "can't be blank"
    end
  end

  # test "toggle settings" do
  # Setting.instance.update(is_reservations_open: true, is_emailing_enabled: true, is_sms_enabled: true)

  # # visit admin_settings_url
  # # find('input[name="setting[is_reservations_open]"]', visible: :all).set(false)
  # # assert_text 'Setting updated successfully', wait: 5

  # # sleep 3
  # visit admin_settings_url
  # sleep 0.25
  # # assert_not Setting.instance.is_reservations_open?

  # find('#emailing-toggle').click
  # sleep 0.25
  # assert find("#emailing-toggle").value == "false"

  # find('#sms-toggle').click
  # sleep 2

  # assert_not Setting.instance.is_sms_enabled?

  # find('#routing-toggle').click
  # sleep 2
  # assert_not Setting.instance.is_routing_enabled?

  # end

  test "routing toggle saves immediately" do
    visit admin_settings_section_path("location_services")

    initial = Setting.instance.reload.is_routing_enabled

    within "section#location-services" do
      find("#routing-toggle").click
      assert_text "Saved"
    end

    assert_equal !initial, Setting.instance.reload.is_routing_enabled
  end

  test "reservations toggle lives in The Event panel" do
    visit admin_settings_section_path("event")

    within "section.admin-panel", text: "The Event" do
      assert_selector "#reservations-toggle"
      assert_field "Reservations Closed Message"
      assert_field "Suggested Donation"
      assert_text "Displayed on the public home page in place of the reservation form when Enable Reservations is off."
    end

    assert_selector "#reservations-toggle", count: 1
  end

  test "reservations toggle saves immediately" do
    visit admin_settings_section_path("event")

    initial = Setting.instance.reload.is_reservations_open

    within "section.admin-panel", text: "The Event" do
      find("#reservations-toggle").click
      assert_text "Saved"
    end

    assert_equal !initial, Setting.instance.reload.is_reservations_open
  end

  test "organization settings live in the Organization panel" do
    visit admin_settings_section_path("organization")

    within "section.admin-panel", text: "Organization" do
      assert_field "Organization Name"
      assert_field "Organization URL"
      assert_button "Save Organization Settings"
    end

    visit admin_settings_section_path("site_details")

    within "section#site-details" do
      assert_field "Site URL"
      assert_field "Time Zone"
      assert_field "Default Country"
      assert_field "Default Phone Country"
      assert_button "Save Site Details"
    end

    visit admin_settings_section_path("event")

    within "section.admin-panel", text: "The Event" do
      assert_no_field "Organization Name"
      assert_no_field "Organization URL"
    end
  end

  test "organization panel saves its settings" do
    visit admin_settings_section_path("organization")

    within "section.admin-panel", text: "Organization" do
      fill_in "Organization Name", with: "Troop 200"
      fill_in "Organization URL", with: "https://troop200.example.com"
      click_on "Save Organization Settings"
    end

    assert_text "Settings were successfully updated"

    setting = Setting.instance.reload
    assert_equal "Troop 200", setting.organization_name
    assert_equal "https://troop200.example.com", setting.organization_url
  end

  test "site details panel saves its settings" do
    visit admin_settings_section_path("site_details")

    within "section#site-details" do
      fill_in "Site URL", with: "https://trees.example.com"
      select "UTC", from: "Time Zone"
      fill_in "Default Country", with: "Canada"
      fill_in "Default Phone Country", with: "CA"
      click_on "Save Site Details"
    end

    assert_text "Settings were successfully updated"

    setting = Setting.instance.reload
    assert_equal "https://trees.example.com", setting.site_url
    assert_equal "UTC", setting.time_zone
    assert_equal "Canada", setting.default_country
    assert_equal "CA", setting.phone_default_country
  end

  test "event contacts describe that fields are optional" do
    visit admin_settings_section_path("event")

    within "section.admin-panel", text: "The Event" do
      assert_text "All fields are optional. Any information provided here will be displayed on the public site so customers can reach the event organizers."
    end
  end

  test "pickups portal settings live in the Pickups Portal panel" do
    visit admin_settings_section_path("pickups")

    within "section.admin-panel", text: "Pickups Portal" do
      assert_selector "#pickups-toggle"
      assert_field "Password"
      assert_button "Save Portal Settings"
      assert_no_text "Turn the driver portal on or off."
    end

    assert_selector "#pickups-toggle", count: 1
  end

  test "pickups portal toggle saves immediately" do
    visit admin_settings_section_path("pickups")

    initial = Setting.instance.reload.is_pickups_site_enabled

    within "section.admin-panel", text: "Pickups Portal" do
      find("#pickups-toggle").click
      assert_text "Saved"
    end

    assert_equal !initial, Setting.instance.reload.is_pickups_site_enabled
  end

  test "sms settings live in the SMS panel" do
    visit admin_settings_section_path("sms")

    within "section#sms" do
      assert_selector "#sms-toggle"
      assert_field "Account SID"
      assert_field "Auth Token"
      assert_field "From Number"
      assert_field "Quick Responses"
      assert_field "First Message"
      assert_field "Follow-up Message"
      assert_field "Webhook URL", with: api_v1_sms_reply_url
      assert_button "Save SMS Settings"
    end

    assert_selector "#sms-toggle", count: 1
  end

  test "sms panel saves credentials" do
    visit admin_settings_section_path("sms")

    within "section#sms" do
      fill_in "Account SID", with: "AC123456"
      fill_in "Auth Token", with: "token-123"
      fill_in "From Number", with: "+15555550123"
      fill_in "Quick Responses", with: "Thanks!\nOn our way."
      fill_in "First Message", with: "First custom message"
      fill_in "Follow-up Message", with: "Follow-up custom message"
      click_on "Save SMS Settings"
    end

    assert_text "Settings were successfully updated"

    setting = Setting.instance.reload
    assert_equal "AC123456", setting.twilio_account_sid
    assert_equal "token-123", setting.twilio_auth_token
    assert_equal "+15555550123", setting.twilio_from_number
    assert_equal [ "Thanks!", "On our way." ], setting.sms_quick_response_list
    assert_equal "First custom message", setting.missing_tree_sms_message
    assert_equal "Follow-up custom message", setting.missing_tree_sms_follow_up_message
  end

  test "sms toggle saves immediately" do
    visit admin_settings_section_path("sms")

    initial = Setting.instance.reload.is_sms_enabled

    within "section#sms" do
      find("#sms-toggle").click
      assert_text "Saved"
    end

    assert_equal !initial, Setting.instance.reload.is_sms_enabled
  end

  test "email settings live in the Email panel" do
    visit admin_settings_section_path("email")

    within "section#email" do
      assert_selector "#emailing-toggle"
      assert_field "From Address"
      assert_field "SMTP Address"
      assert_field "Port"
      assert_field "Username"
      assert_field "Password"
      assert_field "Authentication"
      assert_field "Encryption"
      assert_field "Days Between Marketing Emails"
      assert_button "Save Email Settings"
    end

    assert_selector "#emailing-toggle", count: 1
  end

  test "email panel saves settings" do
    visit admin_settings_section_path("email")

    within "section#email" do
      fill_in "From Address", with: "Troop 100 <troop100@example.com>"
      fill_in "SMTP Address", with: "smtp.example.com"
      fill_in "Port", with: "587"
      fill_in "Username", with: "smtp-user"
      fill_in "Password", with: "smtp-password"
      select "Plain", from: "Authentication"
      select "STARTTLS (recommended)", from: "Encryption"
      fill_in "Email Batch Quantity", with: "99"
      fill_in "Days Between Marketing Emails", with: "10"
      click_on "Save Email Settings"
    end

    assert_text "Settings were successfully updated"

    setting = Setting.instance.reload
    assert_equal "Troop 100 <troop100@example.com>", setting.email_from_address
    assert_equal "smtp.example.com", setting.smtp_address
    assert_equal 587, setting.smtp_port
    assert_equal "smtp-user", setting.smtp_user_name
    assert_equal "smtp-password", setting.smtp_password
    assert_equal "plain", setting.smtp_authentication
    assert_equal 99, setting.email_batch_quantity
    assert_equal 10, setting.marketing_email_cooldown_days
  end

  test "email toggle saves immediately" do
    visit admin_settings_section_path("email")

    initial = Setting.instance.reload.is_emailing_enabled

    within "section#email" do
      find("#emailing-toggle").click
      assert_text "Saved"
    end

    assert_equal !initial, Setting.instance.reload.is_emailing_enabled
  end

  test "donations settings live in the Donations panel" do
    visit admin_settings_section_path("donations")

    within "section#donations" do
      assert_selector "#donations-toggle"
      assert_field "Secret Key"
      assert_field "Price ID"
      assert_field "Webhook URL", with: api_v1_stripe_webhook_url
      assert_button "Save Donations Settings"
    end

    assert_selector "#donations-toggle", count: 1
  end

  test "donations panel saves settings" do
    visit admin_settings_section_path("donations")

    within "section#donations" do
      fill_in "Secret Key", with: "sk_test_123"
      fill_in "Price ID", with: "price_123"
      click_on "Save Donations Settings"
    end

    assert_text "Settings were successfully updated"

    setting = Setting.instance.reload
    assert_equal "sk_test_123", setting.stripe_secret_key
    assert_equal "price_123", setting.stripe_price_id
  end

  test "donations toggle saves immediately" do
    visit admin_settings_section_path("donations")

    initial = Setting.instance.reload.is_donations_enabled

    within "section#donations" do
      find("#donations-toggle").click
      assert_text "Saved"
    end

    assert_equal !initial, Setting.instance.reload.is_donations_enabled
  end

  test "webhook URLs use the configured Site URL" do
    Setting.instance.update(site_url: "https://trees.example.com")

    visit admin_settings_section_path("donations")

    within "section#donations" do
      assert_field "Webhook URL", with: "https://trees.example.com/api/v1/stripe-webhook"
    end

    visit admin_settings_section_path("sms")

    within "section#sms" do
      assert_field "Webhook URL", with: "https://trees.example.com/api/v1/sms/reply"
    end
  end

  test "location services settings live in the Location Services panel" do
    visit admin_settings_section_path("location_services")

    within "section#location-services" do
      assert_selector "#routing-toggle"
      assert_field "Access Key ID"
      assert_field "Secret Access Key"
      assert_field "Region", placeholder: "us-west-2"
      assert_field "Place Index Name", placeholder: "tree_recycle"
      assert_button "Save Location Services Settings"
      assert_text "If Location Services is not configured, reservations will need to be manually assigned to routes."
    end
  end

  test "location services panel saves settings" do
    visit admin_settings_section_path("location_services")

    within "section#location-services" do
      fill_in "Access Key ID", with: "AKIATEST"
      fill_in "Secret Access Key", with: "secret-test"
      fill_in "Region", with: "us-east-1"
      fill_in "Place Index Name", with: "test-index"
      click_on "Save Location Services Settings"
    end

    assert_text "Settings were successfully updated"

    setting = Setting.instance.reload
    assert_equal "AKIATEST", setting.aws_access_key_id
    assert_equal "secret-test", setting.aws_secret_access_key
    assert_equal "us-east-1", setting.aws_region
    assert_equal "test-index", setting.aws_location_index_name
  end

  test "system panel links to close event" do
    visit admin_settings_section_path("system")

    within "section#close-event" do
      assert_link "Close Event", href: admin_close_event_path
      assert_no_text "Retention (Months)"
    end
  end

  test "data management panel lists the destructive actions with counts" do
    visit admin_settings_section_path("system")

    within "section#data-management" do
      assert_text "Data Management"
      assert_text "Danger zone"
      assert_text "Reset all data to default"
      assert_text "This permanently deletes #{Reservation.count} reservation"
      assert_text "This permanently deletes #{Contact.count} contact"
      assert_text "Sample data is not loaded — run it separately once setup is complete."
      assert_text "This is the most destructive action in the application."
    end
  end

  test "admin can delete all reservations from the data management panel" do
    visit admin_settings_section_path("system")

    within "section#data-management" do
      find("summary", text: "Delete All Reservations").click
      within find("details", text: "Delete All Reservations") do
        fill_in "Type DELETE to confirm", with: "DELETE"
        accept_confirm { click_on "Confirm Delete All Reservations" }
      end
    end

    assert_text "reservations have been deleted"
    assert_equal 0, Reservation.count
    assert_nil Donation.first&.reservation_id
  end

  test "admin can delete all contacts from the data management panel" do
    visit admin_settings_section_path("system")

    within "section#data-management" do
      find("summary", text: "Delete All Contacts").click
      within find("details", text: "Delete All Contacts") do
        fill_in "Type DELETE to confirm", with: "DELETE"
        accept_confirm { click_on "Confirm Delete All Contacts" }
      end
    end

    assert_text "contacts have been deleted"
    assert_equal 0, Contact.count
  end

  test "admin can reset all data and relaunch in maintenance mode" do
    visit admin_settings_section_path("system")

    within "section#data-management" do
      find("summary", text: "Reset All Data to Default").click
      fill_in "Type RESET ALL to confirm", with: "RESET ALL"
      accept_confirm { click_on "Confirm Reset All Data" }
    end

    assert_text "All data has been reset to defaults"
    assert_text "Initial Application Setup"
    assert_equal 0, User.count
    assert_equal 0, Setting.count
    assert_equal MarketingEmailTemplate.default_names.sort, MarketingEmailTemplate.pluck(:name).sort
    assert_equal 0, Reservation.count, "sample data should not be loaded by the reset"

    # Complete first-run setup: the site relaunches down for maintenance with
    # reservations closed until an admin turns them on.
    fill_in "Organization Name", with: "Troop 200"
    fill_in "Site URL", with: "https://example.com"
    fill_in "Default City", with: "Anytown"
    select "New York", from: "Default State"
    fill_in "Event Pickup Start", with: "2024-01-15T14:30"
    fill_in "Event Pickup End", with: "2024-01-15T15:30"
    fill_in "Sign Up Deadline", with: "2024-01-14T16:59"
    fill_in "Admin Email", with: "reset-admin@example.com"
    fill_in "Admin Password", with: "password123456789"
    fill_in "Confirm Admin Password", with: "password123456789"
    click_on "Save Settings"

    # The reset wiped the sessions, so the admin lands on the sign-in page.
    assert_current_path new_admin_session_path

    setting = Setting.instance
    assert setting.is_maintenance_mode?, "site should relaunch down for maintenance"
    assert_not setting.is_reservations_open?, "reservations should stay closed by default"

    visit root_path
    assert_selector "h1", text: "Down for maintenance"
  end

  test "admin can load sample data from the data management panel" do
    visit admin_settings_section_path("system")

    within "section#data-management" do
      accept_confirm { click_on "Load Sample Data" }
    end

    assert_text "Sample data has been loaded"
    assert_operator Reservation.count, :>, 50
    assert_operator Contact.count, :>, 100
  end

  test "a non-admin sees the data management panel but cannot act" do
    sign_in_as(users(:user), true)
    visit admin_settings_section_path("system")

    within "section#data-management" do
      assert_text "Admin only"
      assert_text "Only admins can delete or reset data."
      assert_no_button "Confirm Delete All Reservations"
      assert_no_button "Confirm Delete All Contacts"
      assert_no_button "Confirm Reset All Data"
      assert_no_button "Load Sample Data"
      assert_no_text "Reset All Data to Default"
    end
  end

  test "maintenance toggle takes the public site down and brings it back" do
    visit admin_settings_section_path("system")

    within "section#system" do
      find("#maintenance-mode-toggle").click
      assert_text "Saved"
    end

    assert Setting.instance.reload.is_maintenance_mode?

    visit root_url
    assert_selector "h1", text: "Down for maintenance"
    assert_text "Troop 100 Tree Recycle is temporarily unavailable"

    visit admin_settings_section_path("system")

    within "section#system" do
      find("#maintenance-mode-toggle").click
      assert_text "Saved"
    end

    assert_not Setting.instance.reload.is_maintenance_mode?

    visit root_url
    assert_selector "h1", text: "Make a Reservation"
  end

  test "pickup notice toggle replaces the home page reservation form" do
    Setting.instance.update!(
      contact_name: "Alex Rivera",
      contact_email: "alex@example.com",
      contact_phone: nil,
      contact_sms: nil
    )

    visit admin_settings_section_path("system")

    within "section#system" do
      find("#pickup-notice-toggle").click
      assert_text "Saved"
    end

    assert Setting.instance.reload.is_pickup_notice_enabled?

    visit root_url
    assert_text "We're no longer taking reservations"
    assert_text "Alex Rivera"
    assert_link "alex@example.com", href: "mailto:alex@example.com"
    assert_no_text "Phone"
    assert_no_button "Create Reservation"

    visit admin_settings_section_path("system")

    within "section#system" do
      find("#pickup-notice-toggle").click
      assert_text "Saved"
    end

    assert_not Setting.instance.reload.is_pickup_notice_enabled?

    visit root_url
    assert_button "Create Reservation"
    assert_no_text "We're no longer taking reservations"
  end

  test "page links" do
    visit admin_settings_section_path("system")
    within "section#system" do
      assert_link "System Logs", href: admin_logs_path
      assert_selector "#maintenance-mode-toggle"
      assert_selector "#pickup-notice-toggle"
    end

    visit admin_settings_section_path("pickups")
    within "section#tree-pickups" do
      assert_link "View drivers", href: admin_drivers_path
    end

    visit admin_settings_url
    assert_link "Data", href: admin_data_path
    assert_link "Jobs", href: admin_mission_control_jobs_path
    assert_link "Users", href: admin_users_path
  end

  test "system panel updates the default email logo" do
    image = MarketingEmailTemplate.available_images.first

    visit admin_settings_section_path("system")

    within "section#email-logo" do
      assert_field "Logo Image"
      assert_button "Save Email Logo"
      select image, from: "Logo Image"
      click_on "Save Email Logo"
    end

    assert_text "Settings were successfully updated"
    assert_equal image, Setting.instance.reload.mailer_logo
  end

  test "site content settings live in the Site Content panel" do
    visit admin_settings_section_path("site_content")

    within "section.admin-panel", text: "Site Content" do
      assert_field "Header/Tab Title"
      assert_field "Home Page Image"
      assert_field "Description"
      assert_field "On Day of Pickup Instructions"
      assert_field "Initial Content"
      assert_field "How to Donate"
      assert_field "New Donations Page Content"
      assert_field "Donation Success Content"
      assert_text "Markdown supported"
      assert_selector "a[href='/'][target='_blank'][rel='noopener']", text: "View page"
      assert_selector "a[href='/about'][target='_blank'][rel='noopener']", text: "View page"
      assert_selector "a[href='/thanks'][target='_blank'][rel='noopener']", text: "View page"
      assert_link "Add thank", href: new_admin_thank_path
      assert_link "Manage Thanks", href: admin_thanks_path
      assert_button "Save Site Content"
    end

    visit admin_settings_section_path("event")

    within "section.admin-panel", text: "The Event" do
      assert_no_field "Header/Tab Title"
      assert_no_field "Description"
      assert_no_field "On Day of Pickup Instructions"
      assert_no_field "Initial Content"
      assert_no_field "How to Donate"
      assert_no_field "New Donations Page Content"
      assert_no_field "Donation Success Content"
    end
  end

  test "site content panel saves its settings" do
    visit admin_settings_section_path("site_content")

    within "section.admin-panel", text: "Site Content" do
      fill_in "Header/Tab Title", with: "Home Page Header"
      fill_in "Description", with: "About Event Description"
      fill_in "On Day of Pickup Instructions", with: "On Day of Pickup Instructions do this"
      fill_in "Initial Content", with: "Donations intro copy"
      fill_in "How to Donate", with: "How to donate copy"
      fill_in "New Donations Page Content", with: "New donations page copy"
      fill_in "Donation Success Content", with: "Donation success copy"
      click_on "Save Site Content"
    end

    assert_text "Settings were successfully updated"
    assert_field "Header/Tab Title", with: "Home Page Header"
    assert_field "Description", with: "About Event Description"
    assert_field "On Day of Pickup Instructions", with: "On Day of Pickup Instructions do this"
    assert_field "Initial Content", with: "Donations intro copy"
    assert_field "How to Donate", with: "How to donate copy"
    assert_field "New Donations Page Content", with: "New donations page copy"
    assert_field "Donation Success Content", with: "Donation success copy"
  end

  test "site content panel updates the home page image" do
    image = MarketingEmailTemplate.available_images.first

    visit admin_settings_section_path("site_content")
    within "section.admin-panel", text: "Site Content" do
      select image, from: "Home Page Image"
      click_on "Save Site Content"
    end

    assert_text "Settings were successfully updated"
    assert_equal image, Setting.instance.reload.home_page_image

    visit root_url
    src = find("img.site-home-image")[:src]
    assert_includes src, File.basename(image, ".*")
  end

  test "update event settings" do
    visit admin_settings_section_path("event")

    within "section.admin-panel", text: "The Event" do
      fill_in "Reservations Closed Message", with: "Reservations Closed Message"
      fill_in "Suggested Donation", with: "50"
      fill_in "Contact Name", with: "Contact Name"
      fill_in "Contact Phone", with: "Contact Phone"
      fill_in "Contact Email", with: "email@example.com"
      click_on "Save Settings"
    end

    assert_text "Settings were successfully updated"
    assert_field "Reservations Closed Message", with: "Reservations Closed Message"
    assert_field "Suggested Donation", with: "50"
    assert_field "Contact Name", with: "Contact Name"
    assert_field "Contact Phone", with: "Contact Phone"
    assert_field "Contact Email", with: "email@example.com"
  end

  test "sends a test email from the email settings panel" do
    configure_email!
    original_perform_deliveries = ActionMailer::Base.perform_deliveries
    ActionMailer::Base.perform_deliveries = false

    visit admin_settings_section_path("email")

    within "section#email" do
      fill_in "Send Test Email To", with: "qa@example.com"
      click_on "Send Test Email"
    end

    assert_text "Test email sent to qa@example.com."
  ensure
    ActionMailer::Base.perform_deliveries = original_perform_deliveries
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.smtp_settings = {}
  end

  test "email settings panel warns when smtp settings are incomplete" do
    Setting.instance.update!(smtp_address: nil, smtp_port: nil)

    visit admin_settings_section_path("email")

    within "section#email" do
      fill_in "Send Test Email To", with: "qa@example.com"
      click_on "Send Test Email"
    end

    assert_text Setting.instance.email_configuration_alert(purpose: "sending a test email")
  end
end
