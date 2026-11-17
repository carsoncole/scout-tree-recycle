require "application_system_test_case"

class ThanksTest < ApplicationSystemTestCase
  test "public page thanks supporters" do
    visit thanks_url

    assert_selector "h1", text: "Thank You"
    assert_text Setting::DEFAULT_THANK_YOU_MESSAGE
    assert_text thanks(:one).content
    assert_selector "img[alt='Supporter logo']"
  end

  test "public page omits the message when it is cleared" do
    Setting.instance.update!(thank_you_message: "")

    visit thanks_url

    assert_selector "h1", text: "Thank You"
    assert_no_text Setting::DEFAULT_THANK_YOU_MESSAGE
    assert_text thanks(:one).content
  end
end
