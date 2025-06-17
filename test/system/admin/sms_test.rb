require "application_system_test_case"

class Admin::SmsTest < ApplicationSystemTestCase
  setup do
    @admin = users(:admin)
    sign_in_as(@admin, true)
    Setting.instance.update(is_sms_enabled: true)
  end

  test "visiting the index" do
    visit admin_sms_url
    assert_selector "h1", text: "SMS Messages"
  end

  test "should display canned responses" do
    visit admin_sms_url
    # First, expand a thread to see the canned responses
    first(".cursor-pointer").click

    # Check that canned responses are present
    assert_text "Thank you! I'll let the Scouts know."
    assert_text "Thanks for the update. I'll have them swing by again to pick up the tree."
    assert_text "We are only picking up today, however I can see if we could swing by tomorrow."
    assert_text "Quick Responses:"
  end

  test "should send a new message" do
    visit admin_sms_url

    fill_in "Phone", with: "1234567890"
    fill_in "Body", with: "Test message"
    click_button "Send"

    assert_text "Message sent successfully."
  end

  test "should show disabled SMS message when SMS is disabled" do
    Setting.instance.update(is_sms_enabled: false)
    visit admin_sms_url

    assert_text "SMS messaging is disabled. Enable SMS in Settings to send messages."
  end

  test "should delete conversation on index page" do
    visit admin_sms_url
    accept_confirm do
      first(".delete-button").click
    end
    assert_text "Conversation deleted successfully."
    assert_equal 0, Sms.where(phone: "+12069230400").count
  end

  test "should delete conversation on show page" do
    visit admin_sms_url
    first(".cursor-pointer").click
    accept_confirm do
      first(".delete-button").click
    end
    assert_text "Conversation deleted successfully."
    assert_equal 0, Sms.where(phone: "+12069230400").count
  end
end
