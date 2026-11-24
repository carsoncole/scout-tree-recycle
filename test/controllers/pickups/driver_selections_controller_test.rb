require "test_helper"

class Pickups::DriverSelectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Setting.instance.update!(is_pickups_site_enabled: true, driver_secret_key: "secret")
  end

  test "shows the driver list with the current selection checked" do
    authenticate_driver
    cookies[:pickup_driver_id] = drivers(:driver_one).id.to_s

    get pickups_driver_selection_url

    assert_response :success
    assert_select "h1", "Select Driver"
    assert_select "input[type=radio][name=driver_id]", count: Driver.count
    assert_select "input[type=radio][value=?][checked]", drivers(:driver_one).id
    assert_select "button", text: "Continue Without a Driver"
  end

  test "shows no driver checked when the user continued without one" do
    authenticate_driver
    cookies[:pickup_driver_id] = "none"

    get pickups_driver_selection_url

    assert_response :success
    assert_select "input[type=radio][checked]", count: 0
  end

  test "saves the selected driver in a permanent cookie" do
    authenticate_driver

    patch pickups_driver_selection_url, params: { driver_id: drivers(:driver_two).id }

    assert_redirected_to pickups_root_url
    assert_equal drivers(:driver_two).id.to_s, cookies[:pickup_driver_id]

    follow_redirect!
    assert_response :success
    assert_select "h1", "Pickups"
    assert_select ".admin-page-actions a[href=?]", pickups_driver_selection_path,
                  text: "Driver: #{drivers(:driver_two).name}"
  end

  test "continuing without a driver records the choice and shows the overview" do
    authenticate_driver

    patch pickups_driver_selection_url, params: { driver_id: "" }

    assert_redirected_to pickups_root_url
    assert_equal "none", cookies[:pickup_driver_id]

    follow_redirect!
    assert_response :success
    assert_select "h1", "Pickups"
  end

  test "rejects an unknown driver" do
    authenticate_driver

    patch pickups_driver_selection_url, params: { driver_id: "0" }

    assert_redirected_to pickups_driver_selection_url
    follow_redirect!
    assert_select ".flash", text: /That driver could not be found/
  end

  test "should not show without driver key" do
    get pickups_driver_selection_url
    assert_response :unauthorized
  end

  test "should not update without driver key" do
    patch pickups_driver_selection_url, params: { driver_id: drivers(:driver_one).id }
    assert_response :unauthorized
  end

  test "should not show when pickups site disabled" do
    Setting.instance.update!(is_pickups_site_enabled: false)
    get pickups_driver_selection_url, params: { driver_secret_key: "secret" }
    assert_response :unauthorized
  end

  private

  def authenticate_driver
    get pickups_root_url, params: { driver_secret_key: "secret" }
  end
end
