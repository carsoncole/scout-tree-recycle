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

    test "should display the configured thank you message on about" do
      Setting.instance.update!(thank_you_message: "Custom thanks from #{Setting.instance.organization_name}.")

      get about_url

      assert_response :success
      assert_includes response.body, "Custom thanks from Troop 100."
    end

    test "should link to thanks when thanks exist" do
      get about_url

      assert_select "a[href=?]", thanks_path, text: "See our thanks"
    end

    test "should not link to thanks when none exist" do
      Thank.delete_all

      get about_url

      assert_response :success
      assert_select "a[href=?]", thanks_path, text: "See our thanks", count: 0
    end

    test "should hide the thank you section when the message is cleared" do
      Setting.instance.update!(thank_you_message: "")

      get about_url

      assert_response :success
      assert_select "h3", text: "Thank you", count: 0
      assert_select "a[href=?]", thanks_path, text: "See our thanks", count: 0
      assert_not_includes response.body, Setting::DEFAULT_THANK_YOU_MESSAGE
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
