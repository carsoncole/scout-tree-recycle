class Reservation < ApplicationRecord
  validates :name, :street, :email, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, format: { with: /\A\+?[\d\s-]+\z/, allow_blank: true }
end 