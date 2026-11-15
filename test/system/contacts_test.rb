require "application_system_test_case"

class ContactsTest < ApplicationSystemTestCase
  test "unsubscribe from contacts" do
    visit unsubscribe_contact_url(contacts(:full).id)
    click_on "Yes, Unsubscribe Me"
    assert_text "You have been successfully unsubscribed from our mailing list."
    assert_not Contact.exists?(contacts(:full).id)
  end

  test "unsubscribe from contacts with wrong id" do
    visit unsubscribe_contact_url(1234567890)
    assert_text "Your email has already been unsubscribed."
    assert_text "Make a Reservation"
  end
end
