require "application_system_test_case"

class ContactsTest < ApplicationSystemTestCase
  test "unsubscribe from contacts" do
    contact = contacts(:full)
    visit unsubscribe_contact_url(contact.id)
    click_on "Yes, Unsubscribe Me"
    assert_text "You have been successfully unsubscribed from our mailing list."
    assert contact.reload.is_unsubscribed_from_marketing?
  end

  test "unsubscribe from contacts with wrong id" do
    visit unsubscribe_contact_url("00000000-0000-0000-0000-000000000000")
    assert_text "Your email has already been unsubscribed."
    assert_text "Make a Reservation"
  end
end
