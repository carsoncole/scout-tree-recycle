require "test_helper"

class ContactsControllerTest < ActionDispatch::IntegrationTest
  test "should get unsubscribe" do
    get unsubscribe_contact_url(contacts(:full))
    assert_response :success
  end

  test "should unsubscribe contact" do
    contact = contacts(:full)

    assert_no_difference "Contact.count" do
      post unsubscribe_contact_url(contact)
    end

    assert_redirected_to root_path
    assert_equal "You have been successfully unsubscribed from our mailing list.", flash[:notice]
    assert contact.reload.is_unsubscribed_from_marketing?
  end

  test "unsubscribing non-existent contact should redirect to root" do
    get unsubscribe_contact_url("00000000-0000-0000-0000-000000000000")
    assert_redirected_to root_path
    assert_equal "Your email has already been unsubscribed.", flash[:alert]
  end

  test "already unsubscribed contact should redirect to root on get" do
    contact = contacts(:full)
    contact.unsubscribe_from_marketing!

    get unsubscribe_contact_url(contact)
    assert_redirected_to root_path
    assert_equal "Your email has already been unsubscribed.", flash[:alert]
  end

  test "post unsubscribing non-existent contact should redirect to root" do
    post unsubscribe_contact_url("00000000-0000-0000-0000-000000000000")
    assert_redirected_to root_path
    assert_equal "Your email has already been unsubscribed.", flash[:alert]
  end

  test "one-click unsubscribe marks contact as unsubscribed" do
    contact = contacts(:full)

    post unsubscribe_contact_url(contact), params: { "List-Unsubscribe" => "One-Click" }

    assert_response :ok
    assert contact.reload.is_unsubscribed_from_marketing?
  end

  test "one-click unsubscribe is safe when already unsubscribed" do
    contact = contacts(:full)
    contact.unsubscribe_from_marketing!

    post unsubscribe_contact_url(contact), params: { "List-Unsubscribe" => "One-Click" }

    assert_response :ok
    assert contact.reload.is_unsubscribed_from_marketing?
  end
end
