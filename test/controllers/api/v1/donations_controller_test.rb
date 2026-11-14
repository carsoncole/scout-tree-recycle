require "test_helper"

class Api::V1::DonationsControllerTest < ActionDispatch::IntegrationTest
  test "should process a Stripe webhook" do
    event = Object.new
    processor = Object.new
    def processor.process
      true
    end

    original_retrieve = Stripe::Event.method(:retrieve)
    original_new = StripeCharge.method(:new)

    Stripe::Event.define_singleton_method(:retrieve) { |_id| event }
    StripeCharge.define_singleton_method(:new) { |_event| processor }

    post api_v1_stripe_webhook_url, params: { id: "evt_test" }

    assert_response :created
  ensure
    Stripe::Event.define_singleton_method(:retrieve, original_retrieve)
    StripeCharge.define_singleton_method(:new, original_new)
  end
end
