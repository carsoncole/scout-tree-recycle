require "test_helper"

class ThanksControllerTest < ActionDispatch::IntegrationTest
  test "shows the public page with the default thank you message" do
    get thanks_url

    assert_response :success
    assert_select "h1", text: "Thank You"
    assert_includes response.body, Setting::DEFAULT_THANK_YOU_MESSAGE
    assert_includes response.body, thanks(:one).content
  end

  test "shows the configured thank you message" do
    Setting.instance.update!(thank_you_message: "Custom thanks to our supporters.")

    get thanks_url

    assert_response :success
    assert_includes response.body, "Custom thanks to our supporters."
    assert_not_includes response.body, Setting::DEFAULT_THANK_YOU_MESSAGE
  end

  test "shows the default message when there are no thanks" do
    Thank.delete_all

    get thanks_url

    assert_response :success
    assert_includes response.body, Setting::DEFAULT_THANK_YOU_MESSAGE
  end

  test "omits the thank you message when it is cleared" do
    Setting.instance.update!(thank_you_message: "")

    get thanks_url

    assert_response :success
    assert_select "h1", text: "Thank You"
    assert_not_includes response.body, Setting::DEFAULT_THANK_YOU_MESSAGE
  end

  test "omits the image frame when a thank has no image bytes" do
    thank = thanks(:one)
    thank.update_columns(image: "")

    get thanks_url

    assert_response :success
    assert_includes response.body, thank.content
    assert_select "img[src=?]", image_thank_path(thank, v: thank.updated_at.to_i), count: 0
  end

  test "displays a thank that has no content" do
    thank = Thank.create!(content: nil, image: "bytes", image_content_type: "image/jpeg")

    get thanks_url

    assert_response :success
    assert_select "img[src=?]", image_thank_path(thank, v: thank.updated_at.to_i)
  end

  test "serves the stored image with its content type" do
    thank = thanks(:one)

    get image_thank_url(thank)

    assert_response :success
    assert_equal "image/png", response.media_type
    assert_equal thank.image, response.body
  end
end
