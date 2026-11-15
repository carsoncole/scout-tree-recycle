require "application_system_test_case"

class CreditsTest < ApplicationSystemTestCase
  test "visiting the credits page" do
    visit credits_url

    assert_selector "h1", text: "About This App"
    assert_text "Carson Cole"
    assert_link "GitHub", href: "https://github.com/carsoncole"
    assert_link "carson.cole@gmail.com", href: "mailto:carson.cole@gmail.com"
  end

  test "reaching the page from the footer" do
    visit root_url

    click_link "About this app"

    assert_selector "h1", text: "About This App"
  end
end
