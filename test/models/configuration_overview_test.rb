require "test_helper"

class ConfigurationOverviewTest < ActiveSupport::TestCase
  setup do
    @setting = settings(:one)
  end

  test "groups follow the settings sections" do
    expected = %w[event organization site_details site_content pickups sms email donations location_services]
    assert_equal expected, overview.groups.map(&:key)
  end

  test "every group reports entries" do
    overview.groups.each do |group|
      assert group.entries.size.positive?, "#{group.key} group has no entries"
    end
  end

  test "flags required settings as missing when blank" do
    @setting.site_url = nil

    assert_equal :missing, entry_for(:site_url).status
  end

  test "flags required settings as configured when set" do
    @setting.site_url = "https://example.com"

    assert_equal :configured, entry_for(:site_url).status
  end

  test "reports values that still match their default" do
    assert_equal :default, entry_for(:time_zone).status
    assert_equal :default, entry_for(:suggested_donation).status
  end

  test "reports the reservations toggle against the closed default" do
    assert_equal :configured, entry_for(:is_reservations_open).status

    @setting.is_reservations_open = false

    assert_equal :default, entry_for(:is_reservations_open).status
  end

  test "home page header derived from the organization name is the default" do
    assert_equal :default, entry_for(:home_page_header).status

    @setting.home_page_header = "Custom Header"

    assert_equal :configured, entry_for(:home_page_header).status
  end

  test "feature credentials are only required while the feature is enabled" do
    @setting.twilio_account_sid = nil
    @setting.is_sms_enabled = false

    assert_equal :not_needed, entry_for(:twilio_account_sid).status

    @setting.is_sms_enabled = true

    assert_equal :missing, entry_for(:twilio_account_sid).status

    @setting.twilio_account_sid = "AC123"

    assert_equal :configured, entry_for(:twilio_account_sid).status
  end

  test "marked secrets are flagged so views can mask them" do
    @setting.twilio_auth_token = "secret-token"

    assert entry_for(:twilio_auth_token).secret
    assert entry_for(:smtp_password).secret
    assert entry_for(:stripe_secret_key).secret
    assert entry_for(:aws_secret_access_key).secret
    assert entry_for(:driver_secret_key).secret
    assert_not entry_for(:twilio_account_sid).secret
  end

  test "reports optional unset values" do
    assert_equal :not_set, entry_for(:contact_name).status
  end

  test "counts missing settings across groups" do
    assert_equal 1, overview.missing_count

    @setting.site_url = "https://example.com"

    assert_equal 0, overview.missing_count
  end

  private

  def overview
    ConfigurationOverview.new(@setting)
  end

  def entry_for(attribute)
    overview.groups.flat_map(&:entries).find { |entry| entry.attribute == attribute }
  end
end
