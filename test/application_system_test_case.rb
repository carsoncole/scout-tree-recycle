require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  SETTING_ATTRIBUTES = YAML.load_file(Rails.root.join("test/fixtures/settings.yml")).fetch("one").symbolize_keys.freeze

  driven_by :selenium, using: :chrome, screen_size: [ 1400, 1400 ]

  teardown do
    Setting.delete_all
    Setting.create!(SETTING_ATTRIBUTES)
  end
end
