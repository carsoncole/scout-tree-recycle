module Api
  module V1
    class DonationsController < ActionController::API
      include StripeConfigurable

      def stripe_webhook
        event = Stripe::Event.retrieve(params[:id])
        StripeCharge.new(event).process
        head :created
      rescue Stripe::APIConnectionError, Stripe::StripeError => e
        Rails.error.report(e, handled: true, context: { params: params.to_unsafe_h })
        head :bad_request
      end
    end
  end
end
