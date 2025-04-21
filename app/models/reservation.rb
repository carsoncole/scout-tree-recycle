class Reservation < ApplicationRecord
  validates :name, :street, :email, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, format: { with: /\A\+?[\d\s-]+\z/, allow_blank: true }

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
