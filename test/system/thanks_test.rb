require "application_system_test_case"

class ThanksTest < ApplicationSystemTestCase
  test "public page thanks supporters" do
    visit thanks_url

    assert_selector "h1", text: "Thank You"
    assert_text "Troop 100 would like to extend a special thank you to the following supporter."
    assert_text thanks(:one).content
    assert_selector "img[alt='Supporter logo']"
  end
end
