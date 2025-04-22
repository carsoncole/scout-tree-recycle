class Reservation < ApplicationRecord
  include Geocodable

  validates :name, :street, :email, :city, :state, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, format: { with: /\A\+?[\d\s-]+\z/, allow_blank: true }

  enum :donation, { online_donation: 1, cash_or_check_donation: 2, no_donation: 3 }
  enum :status, { in_process: 0, pending_pickup: 1, picked_up: 2, missing: 3, cancelled: 4, archived: 99, remind_me: 999 }, default: :in_process

  attribute :city, :string, default: -> { Setting.instance.default_city }
  attribute :state, :string, default: -> { Setting.instance.default_state }
  attribute :country, :string, default: "United States"

  before_save :normalize_phone!
  before_save :downcase_email!

  private

  def normalize_phone!
    self.phone = Phonelib.parse(phone).full_e164.presence if phone.present?
  end

  def downcase_email!
    self.email = self.email.downcase
  end
end
