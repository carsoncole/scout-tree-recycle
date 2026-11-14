module StripeConfigurable
  extend ActiveSupport::Concern

  included do
    before_action :configure_stripe
  end

  private

  def configure_stripe
    Stripe.api_key = Setting.instance&.stripe_secret_key
  end
end
