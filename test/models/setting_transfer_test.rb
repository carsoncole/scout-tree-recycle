require "test_helper"

class SettingTransferTest < ActiveSupport::TestCase
  test "exportable_attributes excludes identifiers and runtime timestamps" do
    attrs = SettingTransfer.exportable_attributes

    assert_includes attrs, "organization_name"
    assert_includes attrs, "smtp_password"
    assert_not_includes attrs, "id"
    assert_not_includes attrs, "created_at"
    assert_not_includes attrs, "updated_at"
    assert_not_includes attrs, "reservations_export_last_sent_at"
  end

  test "export returns a versioned json envelope with portable setting attributes" do
    setting = Setting.instance
    setting.update!(smtp_password: "secret-password", twilio_auth_token: "twilio-secret")

    payload = JSON.parse(SettingTransfer.export(setting))

    assert_equal "tree-recycle-settings", payload["format"]
    assert_equal 1, payload["version"]
    assert payload["exported_at"].present?
    assert_equal setting.organization_name, payload.dig("setting", "organization_name")
    assert_equal "secret-password", payload.dig("setting", "smtp_password")
    assert_equal "twilio-secret", payload.dig("setting", "twilio_auth_token")
    assert_not payload["setting"].key?("id")
    assert_not payload["setting"].key?("created_at")
    assert_not payload["setting"].key?("updated_at")
    assert_not payload["setting"].key?("reservations_export_last_sent_at")
  end

  test "import updates the existing singleton setting" do
    setting = Setting.instance
    json = SettingTransfer.export(setting)
    payload = JSON.parse(json)
    payload["setting"]["organization_name"] = "Imported Troop"
    payload["setting"]["default_city"] = "Portland"

    result = SettingTransfer.new(json: payload.to_json).import

    assert result.success?
    assert_equal "Imported Troop", setting.reload.organization_name
    assert_equal "Portland", setting.default_city
  end

  test "import creates a setting when none exists" do
    Setting.delete_all

    payload = {
      "format" => "tree-recycle-settings",
      "version" => 1,
      "setting" => {
        "organization_name" => "Fresh Troop",
        "default_city" => "Seattle",
        "default_state" => "WA",
        "event_pickup_start" => "2099-01-06T08:00:00Z",
        "event_pickup_end" => "2099-01-06T15:00:00Z",
        "event_sign_up_deadline" => "2099-01-05T23:59:00Z"
      }
    }

    assert_difference "Setting.count", 1 do
      result = SettingTransfer.new(json: payload.to_json).import
      assert result.success?
    end

    assert_equal "Fresh Troop", Setting.instance.organization_name
  end

  test "import ignores unknown keys and excluded attributes" do
    setting = Setting.instance
    original_id = setting.id
    original_created_at = setting.created_at

    payload = {
      "format" => "tree-recycle-settings",
      "version" => 1,
      "setting" => {
        "organization_name" => "Updated Troop",
        "id" => 999999,
        "created_at" => "2000-01-01T00:00:00Z",
        "unknown_attribute" => "ignored"
      }
    }

    result = SettingTransfer.new(json: payload.to_json).import

    assert result.success?
    setting.reload
    assert_equal "Updated Troop", setting.organization_name
    assert_equal original_id, setting.id
    assert_equal original_created_at.to_i, setting.created_at.to_i
  end

  test "import rejects invalid json" do
    result = SettingTransfer.new(json: "{not json").import

    assert_not result.success?
    assert_includes result.errors, "Settings file is not valid JSON."
  end

  test "import rejects unsupported format or version" do
    bad_format = SettingTransfer.new(json: { format: "nope", version: 1, setting: {} }.to_json).import
    bad_version = SettingTransfer.new(json: { format: "tree-recycle-settings", version: 999, setting: {} }.to_json).import

    assert_not bad_format.success?
    assert_includes bad_format.errors, "Settings file is not a recognized Tree Recycle settings export."
    assert_not bad_version.success?
    assert_match(/not supported/, bad_version.errors.first)
  end

  test "import rejects missing setting payload" do
    result = SettingTransfer.new(json: { format: "tree-recycle-settings", version: 1 }.to_json).import

    assert_not result.success?
    assert_includes result.errors, "Settings file is invalid: missing setting data."
  end

  test "import returns validation errors and does not persist invalid changes" do
    setting = Setting.instance
    original_name = setting.organization_name

    payload = {
      "format" => "tree-recycle-settings",
      "version" => 1,
      "setting" => { "organization_name" => "" }
    }

    result = SettingTransfer.new(json: payload.to_json).import

    assert_not result.success?
    assert result.errors.any? { |error| error.include?("Organization name") }
    assert_equal original_name, setting.reload.organization_name
  end
end
