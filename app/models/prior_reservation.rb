class PriorReservation < ApplicationRecord
  IMPORTABLE_FIELDS = {
    "name" => "Name",
    "email" => "Email",
    "mobile" => "Mobile",
    "street" => "Street"
  }.freeze

  IMPORTABLE_FIELD_ALIASES = {
    "name" => %w[full_name customer_name customer],
    "email" => %w[email_address e_mail],
    "mobile" => %w[phone phone_number mobile_phone cell cell_phone],
    "street" => %w[address street_address pickup_address]
  }.freeze
  validates :name, :email, presence: true
  validates :email, uniqueness: true

  normalizes :email, with: ->(e) { e.strip.downcase }

  def self.remove_old_prior_reservations!
    retention_months = Setting.instance&.prior_reservation_retention_months || 24
    PriorReservation.where("created_at < ?", retention_months.months.ago).destroy_all
  end

  def marketing_email_cooldown_active?
    return false if marketing_1_email_sent_at.blank?

    marketing_1_email_sent_at > Setting.instance.marketing_email_cooldown_days.days.ago
  end

  def self.clear_email_flags!
    PriorReservation.update_all(marketing_1_email_sent_at: nil, marketing_2_email_sent_at: nil)
  end
end
