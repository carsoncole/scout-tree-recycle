require "test_helper"

class ThanksControllerTest < ActionDispatch::IntegrationTest
  test "shows the public page with a singular thank you" do
    get thanks_url

    assert_response :success
    assert_select "h1", text: "Thank You"
    assert_includes response.body, "Troop 100 would like to extend a special thank you to the following supporter."
    assert_includes response.body, thanks(:one).content
  end

  test "uses plural wording when there are multiple supporters" do
    Thank.create!(content: "Thanks to the Riverside Garden Club.", image: "bytes", image_content_type: "image/jpeg")

    get thanks_url

    assert_response :success
    assert_includes response.body, "the following supporters."
  end

  test "shows an empty state when there are no thanks" do
    Thank.delete_all

    get thanks_url

    assert_response :success
    assert_includes response.body, "We are grateful for every supporter of Troop 100."
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
