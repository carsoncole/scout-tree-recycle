class PriorReservation < ApplicationRecord
  validates :name, :email, presence: true
end
