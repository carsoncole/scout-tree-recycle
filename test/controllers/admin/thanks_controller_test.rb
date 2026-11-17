require "test_helper"

class Admin::ThanksControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin)
  end

  test "requires authentication" do
    Session.delete_all
    Current.reset
    cookies.delete(:session_id)

    get admin_thanks_url

    assert_redirected_to new_admin_session_url
  end

  test "redirects non-admin users to settings" do
    sign_in users(:user)

    get admin_thanks_url

    assert_redirected_to admin_settings_path
    assert_equal "You are not authorized to manage thanks.", flash[:alert]
  end

  test "lists thanks for admins" do
    get admin_thanks_url

    assert_response :success
    assert_select "h1", text: "Thanks"
    assert_includes response.body, thanks(:one).content
  end

  test "creates a thank with an uploaded image" do
    assert_difference("Thank.count") do
      post admin_thanks_url, params: {
        thank: {
          content: "Thanks to the Riverside Garden Club.",
          image_upload: fixture_file_upload("thanks.png", "image/png")
        }
      }
    end

    assert_redirected_to admin_thanks_url
    assert_equal "Thank was successfully created.", flash[:notice]

    thank = Thank.recent.first
    assert_equal "image/png", thank.image_content_type
    assert thank.image.present?
  end

  test "rejects an unsupported image type" do
    assert_no_difference("Thank.count") do
      post admin_thanks_url, params: {
        thank: {
          content: "Thanks!",
          image_upload: fixture_file_upload("thanks.png", "text/plain")
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "updates content without replacing the image" do
    thank = thanks(:one)

    patch admin_thank_url(thank), params: { thank: { content: "Updated thanks" } }

    assert_redirected_to admin_thanks_url
    assert_equal "Updated thanks", thank.reload.content
    assert_equal "image/png", thank.image_content_type
    assert_equal "supporter-logo-bytes", thank.image
  end

  test "deletes a thank" do
    assert_difference("Thank.count", -1) do
      delete admin_thank_url(thanks(:one))
    end

    assert_redirected_to admin_thanks_url
    assert_equal "Thank was successfully deleted.", flash[:notice]
  end

  test "does not let non-admin users create thanks" do
    sign_in users(:user)

    assert_no_difference("Thank.count") do
      post admin_thanks_url, params: {
        thank: { content: "Thanks!", image_upload: fixture_file_upload("thanks.png", "image/png") }
      }
    end

    assert_redirected_to admin_settings_path
  end
end
