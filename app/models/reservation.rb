class Reservation < ApplicationRecord
  validates :name, :street_address, :email, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :mobile, format: { with: /\A\+?[\d\s-]+\z/, allow_blank: true }
end 