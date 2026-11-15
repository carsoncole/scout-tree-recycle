class Donation < ApplicationRecord
  belongs_to :reservation, optional: true
  validates :form, presence: true

  enum :form, { online: 1, cash_or_check: 2 }, default: 1
end
