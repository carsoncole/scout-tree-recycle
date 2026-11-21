class Donation < ApplicationRecord
  belongs_to :reservation, optional: true
  validates :form, presence: true

  enum :form, { online: 1, cash_or_check: 2 }, default: 1

  # Payment statuses reported by Stripe that mean the donation was made.
  PAID_PAYMENT_STATUSES = %w[paid succeeded].freeze

  scope :received, -> { where(payment_status: PAID_PAYMENT_STATUSES) }

  # Records a donation log when the donation is paid. Donations without a
  # reservation (general donations) have no reservation to associate.
  after_save :log_donation_made!, if: -> {
    reservation.present? && saved_change_to_payment_status? && payment_status.in?(PAID_PAYMENT_STATUSES)
  }

  private

  def log_donation_made!
    Log.create(
      log_type: "donation",
      reservation: reservation,
      message: "#{form.humanize} donation received#{formatted_amount} — #{reservation.name} (#{reservation.email})",
      context: { donation_id: id, amount: amount&.to_s, payment_status: payment_status }
    )
  rescue StandardError => e
    Rails.logger.error("Donation activity could not be logged: #{e.class}: #{e.message}")
  end

  def formatted_amount
    amount.present? ? " #{format("$%.2f", amount)}" : ""
  end
end
