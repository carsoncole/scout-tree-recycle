require "test_helper"

class Admin::ContactsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    sign_in
    get new_admin_contact_url
    assert_response :success
  end

  test "should get show" do
    sign_in
    get admin_contact_url(contacts(:full))
    assert_response :success
    assert_match "Marketing emails", response.body
    assert_match "Subscribed", response.body
  end

  test "should create contact" do
    sign_in
    assert_difference "Contact.count", 1 do
      post admin_contacts_url, params: {
        contact: {
          name: "New Contact",
          email: "New.Contact@example.com",
          mobile: "+11234567890",
          street: "42 Elm St"
        }
      }
    end

    contact = Contact.find_by(email: "new.contact@example.com")
    assert contact, "expected email to be normalized to lowercase"
    assert_equal "New Contact", contact.name
    assert_not contact.is_unsubscribed_from_marketing?
    assert_redirected_to admin_marketing_index_path
    assert_equal "Contact was successfully created.", flash[:notice]
  end

  test "should create unsubscribed contact" do
    sign_in
    assert_difference "Contact.count", 1 do
      post admin_contacts_url, params: {
        contact: {
          name: "Opted Out",
          email: "opted.out@example.com",
          is_unsubscribed_from_marketing: "1"
        }
      }
    end

    contact = Contact.find_by(email: "opted.out@example.com")
    assert contact.is_unsubscribed_from_marketing?
  end

  test "should not create contact with a duplicate email" do
    sign_in
    assert_no_difference "Contact.count" do
      post admin_contacts_url, params: {
        contact: { name: "Duplicate", email: contacts(:full).email }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should not create contact without a name" do
    sign_in
    assert_no_difference "Contact.count" do
      post admin_contacts_url, params: {
        contact: { name: "", email: "no.name@example.com" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should get edit" do
    sign_in
    get edit_admin_contact_url(contacts(:full))
    assert_response :success
  end

  test "should update contact" do
    sign_in
    contact = contacts(:full)

    patch admin_contact_url(contact), params: {
      contact: { name: "Updated Name", street: "99 Oak Ave", is_unsubscribed_from_marketing: "1" }
    }

    assert_redirected_to admin_marketing_index_path
    assert_equal "Contact was successfully updated.", flash[:notice]

    contact.reload
    assert_equal "Updated Name", contact.name
    assert_equal "99 Oak Ave", contact.street
    assert_equal "trip.wilson@example.com", contact.email
    assert contact.is_unsubscribed_from_marketing?
  end

  test "should not update contact with an invalid email" do
    sign_in
    contact = contacts(:full)

    patch admin_contact_url(contact), params: {
      contact: { email: contacts(:no_mobile).email }
    }

    assert_response :unprocessable_entity
    assert_equal "trip.wilson@example.com", contact.reload.email
  end

  test "should clear marketing email 1 sent date" do
    sign_in
    contact = contacts(:full)
    contact.update!(marketing_1_email_sent_at: 1.day.ago, marketing_2_email_sent_at: 2.days.ago)

    delete clear_marketing_email_1_admin_contact_url(contact)

    assert_redirected_to admin_marketing_index_path
    assert_equal "Marketing email 1 sent date was cleared.", flash[:notice]

    contact.reload
    assert_nil contact.marketing_1_email_sent_at
    assert contact.marketing_2_email_sent_at.present?
  end

  test "should clear marketing email 2 sent date" do
    sign_in
    contact = contacts(:full)
    contact.update!(marketing_1_email_sent_at: 1.day.ago, marketing_2_email_sent_at: 2.days.ago)

    delete clear_marketing_email_2_admin_contact_url(contact)

    assert_redirected_to admin_marketing_index_path
    assert_equal "Marketing email 2 sent date was cleared.", flash[:notice]

    contact.reload
    assert contact.marketing_1_email_sent_at.present?
    assert_nil contact.marketing_2_email_sent_at
  end

  test "should get destroy" do
    sign_in
    delete admin_contact_url(contacts(:full))
    assert_redirected_to admin_marketing_index_path
    assert_equal "Contact was successfully deleted.", flash[:notice]
  end

  test "should not destroy all without confirmation" do
    sign_in
    assert_no_difference "Contact.count" do
      delete destroy_all_admin_contacts_url, params: { confirmation: "no" }
    end
    assert_redirected_to admin_marketing_index_path
    assert_equal "Type DELETE to confirm deletion of all contacts.", flash[:alert]
  end

  test "should destroy all with confirmation" do
    sign_in
    contact_count = Contact.count
    assert_difference "Contact.count", -contact_count do
      delete destroy_all_admin_contacts_url, params: { confirmation: "DELETE" }
    end
    assert_redirected_to admin_marketing_index_path
    assert_equal "#{contact_count} contacts have been deleted.", flash[:notice]
  end

  test "user should not destroy all contacts" do
    sign_in(users(:user))
    assert_no_difference "Contact.count" do
      delete destroy_all_admin_contacts_url, params: { confirmation: "DELETE" }
    end
    assert_redirected_to admin_marketing_index_path
    assert_equal "You are not authorized to delete all contacts.", flash[:alert]
  end
end
