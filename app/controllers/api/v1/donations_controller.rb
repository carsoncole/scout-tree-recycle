module Api
  module V1
    class DonationsController < ActionController::API
      include StripeConfigurable

      def stripe_webhook
        event = Stripe::Event.retrieve(params[:id])
        StripeCharge.new(event).process
        head :created
      rescue Stripe::APIConnectionError, Stripe::StripeError
        head :bad_request
      end
    end
  end
end
