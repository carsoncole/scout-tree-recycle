require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  SETTING_ATTRIBUTES = YAML.load_file(Rails.root.join("test/fixtures/settings.yml")).fetch("one").symbolize_keys.freeze

  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ] do |options|
    # Chrome 157 on macOS 26 crashes renderers with the AperitifHelpers feature.
    options.add_argument("--disable-features=AperitifHelpers")
  end

  setup do
    # Restart the headless browser periodically. Chrome 157 on macOS can lose
    # its DevTools connection after a long run of Selenium tests.
    @@browser_test_count ||= 0
    @@browser_test_count += 1
    Capybara.current_session.quit if (@@browser_test_count % 10).zero?

    Setting.delete_all
    Setting.create!(SETTING_ATTRIBUTES)
  end

  teardown do
    Setting.delete_all
    Setting.create!(SETTING_ATTRIBUTES)
  end

  # Signs into the pickups portal and handles the first-time driver prompt.
  # Pass a driver to select one, or omit it to continue without a driver.
  def sign_in_driver(driver: nil)
    visit pickups_root_url
    fill_in "Password", with: "secret"
    click_on "Access Pickups"

    return unless page.has_selector?("h1", text: "Select Driver")

    if driver
      choose driver.name
      click_on "Save Driver"
    else
      click_on "Continue Without a Driver"
    end
  end

  # Reservation markers open a close-up preview popup first. These helpers keep
  # the two-step flow readable in system tests.
  def select_pickup_marker(reservation)
    find(".pickup-marker-hit[data-marker-id='#{reservation.id}']").click
    assert_selector ".pickup-mini-popup[data-marker-id='#{reservation.id}']"
  end

  def open_pickup_details(reservation)
    select_pickup_marker(reservation)
    find(".pickup-mini-popup[data-marker-id='#{reservation.id}'] .pickup-mini-details").click
    assert_selector "dialog[open]"
  end
end
