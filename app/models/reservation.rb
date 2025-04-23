class Reservation < ApplicationRecord
  include Geocodable

  has_many :donations, dependent: :nullify

  validates :name, :street, :email, :city, :state, presence: true

  enum :status, { reservation_form: 0, address_verification: 1,  donation_type_selection: 2, pending_pickup: 3,picked_up: 4, missing: 5, cancelled: 6, archived: 99 }, default: :reservation_form
  enum :donation, { online_donation: 1, cash_or_check_donation: 2, no_donation: 3 }

  attribute :city, :string, default: -> { Setting.instance.default_city }
  attribute :state, :string, default: -> { Setting.instance.default_state }
  attribute :country, :string, default: "United States"

  before_validation :normalize_phone!
  before_validation :downcase_email!

  def self.open?
    Setting.instance.is_reservations_open?
  end

  def verify_address!
    nil
  end

  def suggested_address?
    nil
  end

  private

  def normalize_phone!
    self.phone = Phonelib.parse(phone).full_e164.presence if phone.present?
  end

  def downcase_email!
    self.email = self.email.downcase if self.email.present?
  end

end
