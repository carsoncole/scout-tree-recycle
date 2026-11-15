require "test_helper"

class ContactsControllerTest < ActionDispatch::IntegrationTest
  test "should get unsubscribe" do
    get unsubscribe_contact_url(contacts(:full))
    assert_response :success
  end

  test "should unsubscribe contact" do
    assert_difference "Contact.count", -1 do
      delete contact_url(contacts(:full))
    end
    assert_redirected_to root_path
    assert_equal "You have been successfully unsubscribed from our mailing list.", flash[:notice]
  end

  test "unsubscribing non-existent contact should redirect to root" do
    get unsubscribe_contact_url(999)
    assert_redirected_to root_path
    assert_equal "Your email has already been unsubscribed.", flash[:alert]
  end

  test "unsubscribing contact should destroy it" do
    assert_difference "Contact.count", -1 do
      delete contact_url(contacts(:full))
    end
    assert_redirected_to root_path
    assert_equal "You have been successfully unsubscribed from our mailing list.", flash[:notice]
  end

  test "delete unsubscribing non-existent contact should redirect to root" do
    delete contact_url(999)
    assert_redirected_to root_path
    assert_equal "Unable to process your unsubscribe request. Please try again later.", flash[:alert]
  end
end
