class Reservation < ApplicationRecord
  include Geocodable

  validates :name, :street, :email, :city, :state, presence: true

  enum :donation, { online_donation: 1, cash_or_check_donation: 2, no_donation: 3 }
  enum :status, { in_process: 0, pending_pickup: 1, picked_up: 2, missing: 3, cancelled: 4, archived: 99, remind_me: 999 }, default: :in_process

  attribute :city, :string, default: -> { Setting.instance.default_city }
  attribute :state, :string, default: -> { Setting.instance.default_state }
  attribute :country, :string, default: "United States"

  before_validation :normalize_phone!
  before_validation :downcase_email!

  def self.open?
    Setting.instance.is_reservations_open?
  end

  private

  def normalize_phone!
    self.phone = Phonelib.parse(phone).full_e164.presence if phone.present?
  end

  def downcase_email!
    self.email = self.email.downcase if self.email.present?
  end

end
