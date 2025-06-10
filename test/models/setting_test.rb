require "test_helper"

class SettingTest < ActiveSupport::TestCase
  test "should set defaults" do
    setting = Setting.new(organization_name: "Troop 100", default_city: "Anytown", default_state: "CA", event_pickup: "2099-01-06 08:00:00", event_pickup_end: "2099-01-06 15:00:00", event_sign_up_deadline: "2099-01-05 11:59:00")
    setting.save!
    assert_equal "Troop 100 Tree Recycle", setting.site_title
    assert_equal "Troop 100 Tree Recycle", setting.home_page_header
  end
end