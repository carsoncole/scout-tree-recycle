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
    first(".admin-conversation-main").click

    # Check that canned responses are present
    assert_text "Thank you! I'll let the Scouts know."
    assert_text "Thanks for the update. I'll have them swing by again to pick up the tree."
    assert_text "We are only picking up today, however I can see if we could swing by tomorrow."
    assert_text "Quick Responses:"
  end

  test "should send a new message" do
    visit admin_sms_url

    fill_in "sms_phone", with: "1234567890"
    fill_in "sms_body", with: "Test message"
    click_button "Send"

    assert_text "Message sent successfully."
    assert Sms.exists?(phone: "+11234567890", body: "Test message")

    # The sent message is recorded and still shown after a full page reload.
    visit admin_sms_url
    conversation = find(".admin-conversation", text: "Test message")
    assert_includes conversation.text, "Sent by #{@admin.email}"
  end

  test "should record a reply sent from the conversation thread" do
    visit admin_sms_thread_url(phone: "+12069230400")

    fill_in "reply-textarea-12069230400", with: "Thread reply"
    click_button "Send Reply"

    assert_text "Thread reply"
    sms = Sms.find_by!(phone: "+12069230400", body: "Thread reply")
    assert_equal @admin, sms.user

    within find(".admin-message--outgoing", text: "Thread reply") do
      assert_selector ".admin-message-sender", text: @admin.email
    end

    visit admin_sms_thread_url(phone: "+12069230400")
    within find(".admin-message--outgoing", text: "Thread reply") do
      assert_selector ".admin-message-sender", text: @admin.email
    end
  end

  test "should show disabled SMS message when SMS is disabled" do
    Setting.instance.update(is_sms_enabled: false)
    visit admin_sms_url

    assert_text "SMS messaging is disabled. Enable SMS in Settings to send messages."
  end

  test "should delete conversation on index page" do
    visit admin_sms_url
    accept_confirm do
      first(".admin-conversation button", text: "Delete").click
    end
    assert_text "Conversation deleted successfully."
    assert_no_text "+12069230400"
  end

  test "should delete conversation on show page" do
    visit admin_sms_url
    accept_confirm do
      page.find(".admin-conversation", text: "2069230400").find("button", text: "Delete").click
    end
    assert_text "Conversation deleted successfully."
    assert_no_text "+12069230400"
  end

  test "should show unviewed incoming SMS badge in navigation" do
    # Visit admin root to see the navigation
    visit admin_root_path
    # Check that the badge shows the correct count (2 unviewed incoming messages)
    assert_selector "a[href='#{admin_sms_path}'] span", text: "2"

    # Visit SMS page and mark messages as viewed
    visit admin_sms_path
    first(".admin-conversation-main").click

    # Go back to admin root and check that badge is gone
    visit admin_root_path
    assert_no_selector "a[href='#{admin_sms_path}'] span"
  end

  test "should not show badge when no unviewed incoming messages" do
    # Ensure no unviewed incoming messages exist
    Sms.incoming.unviewed.destroy_all

    visit admin_root_path

    # Check that no badge is shown
    assert_no_selector "a[href='#{admin_sms_path}'] span"
  end

  test "should list SMS conversations with unviewed incoming messages first, sorted by time descending" do
    # Create conversations with different timestamps and unviewed status
    # Conversation 1: Has unviewed incoming message (most recent)

    Sms.destroy_all
    Sms.create!(
      phone: "+15551234567",
      body: "Unviewed incoming message 1",
      direction: :incoming,
      viewed: false,
      created_at: 1.hour.ago
    )
    Sms.create!(
      phone: "+15551234567",
      body: "Outgoing response 1",
      direction: :outgoing,
      created_at: 30.minutes.ago
    )

    # Conversation 2: Has unviewed incoming message (older)
    Sms.create!(
      phone: "+15551234568",
      body: "Unviewed incoming message 2",
      direction: :incoming,
      viewed: false,
      created_at: 2.hours.ago
    )

    # Conversation 3: All messages viewed (should appear after unviewed)
    Sms.create!(
      phone: "+15551234569",
      body: "Viewed incoming message",
      direction: :incoming,
      viewed: true,
      created_at: 3.hours.ago
    )
    Sms.create!(
      phone: "+15551234569",
      body: "Outgoing response 3",
      direction: :outgoing,
      viewed: true,
      created_at: 2.hours.ago
    )

    # Conversation 4: Only outgoing messages (should appear last)
    Sms.create!(
      phone: "+15551234570",
      body: "Outgoing only message",
      direction: :outgoing,
      viewed: false,
      created_at: 4.hours.ago
    )

    visit admin_sms_path

    # Get all conversation elements
    conversations = page.all(".admin-conversation")

    # Should have 4 conversations
    assert_equal 4, conversations.length

    # First conversation should be the most recent unviewed incoming (phone 1)
    first_conversation = conversations[0]
    assert first_conversation.has_content?("+15551234567")
    assert first_conversation.has_selector?(".admin-unread-dot") # unviewed indicator

    # Second conversation should be the older unviewed incoming (phone 2)
    second_conversation = conversations[1]
    assert second_conversation.has_content?("+15551234568")
    assert second_conversation.has_selector?(".admin-unread-dot") # unviewed indicator

    # Third conversation should be the viewed conversation (phone 3)
    third_conversation = conversations[2]
    assert third_conversation.has_content?("+15551234569")
    assert_not third_conversation.has_selector?(".admin-unread-dot") # should not have unviewed indicator

    # Fourth conversation should be outgoing only (phone 4)
    fourth_conversation = conversations[3]
    assert fourth_conversation.has_content?("+15551234570")
    assert_not fourth_conversation.has_selector?(".admin-unread-dot") # should not have unviewed indicator

    # Verify timestamps are in descending order for conversations with unviewed messages
    first_timestamp = first_conversation.find(".admin-conversation-time").text
    second_timestamp = second_conversation.find(".admin-conversation-time").text

    # Parse timestamps to compare (simplified comparison)
    first_time = Time.parse(first_timestamp)
    second_time = Time.parse(second_timestamp)

    assert first_time >= second_time, "First conversation should be more recent than second"
  end
end
