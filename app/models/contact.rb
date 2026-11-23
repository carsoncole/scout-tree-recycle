class Contact < ApplicationRecord
  MARKETING_EMAIL_COLUMNS = {
    1 => :marketing_1_email_sent_at,
    2 => :marketing_2_email_sent_at
  }.freeze

  BLOCKED_MARKETING_EMAIL_DOMAINS = %w[test example].freeze

  # Columns written to contacts.csv inside a backup zip. The same list is
  # accepted by ContactsRestore when a backup is restored.
  EXPORT_FIELDS = %w[
    name
    email
    street
    mobile
    marketing_1_email_sent_at
    marketing_2_email_sent_at
    is_unsubscribed_from_marketing
    created_at
    updated_at
  ].freeze

  EXPORT_TIMESTAMP_FIELDS = %w[
    marketing_1_email_sent_at
    marketing_2_email_sent_at
    created_at
    updated_at
  ].freeze

  include Mails::Correspondable

  scope :marketing_subscribed, -> { where(is_unsubscribed_from_marketing: false) }
  scope :marketing_unsubscribed, -> { where(is_unsubscribed_from_marketing: true) }
  scope :with_marketable_email_domain, -> {
    where.not("LOWER(email) ~ ?", "@([^@]+\\.)?(#{BLOCKED_MARKETING_EMAIL_DOMAINS.join('|')})$")
  }
  scope :search, ->(query) {
    next if query.blank?

    pattern = "%#{query.to_s.strip}%"
    where(
      "contacts.name ILIKE :pattern OR contacts.email ILIKE :pattern OR " \
      "contacts.street ILIKE :pattern OR contacts.mobile ILIKE :pattern",
      pattern: pattern
    )
  }

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

  def self.blocked_marketing_email_domain?(email)
    domain = email.to_s.strip.downcase.split("@", 2).last.to_s
    BLOCKED_MARKETING_EMAIL_DOMAINS.any? { |blocked| domain == blocked || domain.end_with?(".#{blocked}") }
  end

  def marketable_email_domain?
    !self.class.blocked_marketing_email_domain?(email)
  end

  # Clears a single marketing email send time so the contact can be emailed again.
  def clear_marketing_email!(marketing_email)
    column = MARKETING_EMAIL_COLUMNS[marketing_email.to_i]
    return false if column.blank?

    update(column => nil)
  end

  # True when this contact can be sent the given marketing email now.
  # Excludes unsubscribed contacts, blocked test/example domains, and already-sent emails.
  def eligible_for_marketing_email?(marketing_email)
    return false if is_unsubscribed_from_marketing?
    return false unless marketable_email_domain?

    case marketing_email.to_i
    when 1
      marketing_1_email_sent_at.nil?
    when 2
      marketing_2_email_sent_at.nil?
    else
      false
    end
  end

  def unsubscribe_from_marketing!
    update!(is_unsubscribed_from_marketing: true)
  end

  def self.clear_email_flags!
    Contact.update_all(marketing_1_email_sent_at: nil, marketing_2_email_sent_at: nil)
  end

  def self.to_csv
    require "csv"

    CSV.generate(headers: EXPORT_FIELDS, write_headers: true) do |csv|
      find_each do |contact|
        csv << EXPORT_FIELDS.map { |field| csv_value(contact, field) }
      end
    end
  end

  def self.csv_value(contact, field)
    if EXPORT_TIMESTAMP_FIELDS.include?(field)
      contact.public_send(field)&.iso8601
    else
      contact.public_send(field)
    end
  end
end
