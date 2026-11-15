require "test_helper"

class Admin::MarketingImagesControllerTest < ActionDispatch::IntegrationTest
  test "should list root-level images and their liquid variables" do
    image = MarketingEmailTemplate.available_images.first
    variable = MarketingEmailTemplate.image_variable_for(image)
    sign_in

    get admin_marketing_images_url

    assert_response :success
    assert_includes response.body, "Email Images"
    assert_includes response.body, image
    assert_includes response.body, variable
    assert_not_includes response.body, ".DS_Store"
  end
end
