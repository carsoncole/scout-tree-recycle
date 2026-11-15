require "test_helper"

class PublicControllerTest < ActionDispatch::IntegrationTest
    test "should get index" do
      get root_url
      assert_response :success
    end

    test "should get about" do
      get about_url
      assert_response :success
    end

    test "should get privacy" do
      get privacy_url
      assert_response :success
    end

    test "should get credits" do
      get credits_url
      assert_response :success
    end

    test "should get index with reservations closed" do
      Setting.instance.update(is_reservations_open: false)
      get root_url
      assert_response :success
    end

    test "should use the configured home page image" do
      image = MarketingEmailTemplate.available_images.first
      Setting.instance.update!(home_page_image: image)

      get root_url

      assert_response :success
      assert_includes response.body, File.basename(image, ".*")
    end
end
