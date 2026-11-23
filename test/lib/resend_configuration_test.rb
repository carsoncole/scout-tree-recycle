require "test_helper"

class ResendConfigurationTest < ActiveSupport::TestCase
  test "api key is read from settings on each use" do
    Setting.instance.update!(resend_api_key: "re_first")
    assert_equal "re_first", Resend.api_key.call

    Setting.instance.update!(resend_api_key: "re_second")
    assert_equal "re_second", Resend.api_key.call
  end

  test "ingress signing secret is read from settings" do
    Setting.instance.update!(resend_signing_secret: "whsec_settings")

    controller = ActionMailbox::Ingresses::Resend::InboundEmailsController.new

    assert_equal "whsec_settings", controller.send(:signing_secret)
  end
end
