class Donation < ApplicationRecord
  belongs_to :reservation, optional: true
  validates :form, presence: true

  enum :form, { online: 1, cash_or_check: 2 }, default: 1

  scope :current_event, -> { where("created_at > ?", 6.months.ago) }
end
