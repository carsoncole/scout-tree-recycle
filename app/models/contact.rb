class Contact < ApplicationRecord
  MARKETING_EMAIL_COLUMNS = {
    1 => :marketing_1_email_sent_at,
    2 => :marketing_2_email_sent_at
  }.freeze

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

  scope :marketing_subscribed, -> { where(is_unsubscribed_from_marketing: false) }
  scope :marketing_unsubscribed, -> { where(is_unsubscribed_from_marketing: true) }

  validates :name, :email, presence: true
  validates :email, uniqueness: true

  normalizes :email, with: ->(e) { e.strip.downcase }

  def self.remove_old_contacts!
    retention_months = Setting.instance&.contact_retention_months || 24
    Contact.where("created_at < ?", retention_months.months.ago).destroy_all
  end

  def first_name
    name.to_s.strip.split(/\s+/).first.to_s
  end

  def has_name?
    cleaned_name = name.to_s.strip
    cleaned_name.present? && cleaned_name.downcase != "no name provided"
  end

  def marketing_email_cooldown_active?
    return false if marketing_1_email_sent_at.blank?

    marketing_1_email_sent_at > Setting.instance.marketing_email_cooldown_days.days.ago
  end

  # Clears a single marketing email send time so the contact can be emailed again.
  def clear_marketing_email!(marketing_email)
    column = MARKETING_EMAIL_COLUMNS[marketing_email.to_i]
    return false if column.blank?

    update(column => nil)
  end

  def unsubscribe_from_marketing!
    update!(is_unsubscribed_from_marketing: true)
  end

  def self.clear_email_flags!
    Contact.update_all(marketing_1_email_sent_at: nil, marketing_2_email_sent_at: nil)
  end
end
