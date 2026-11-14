class Zone < ApplicationRecord
  has_many :routes, -> { order(:name) }, dependent: :nullify
  has_many :reservations, through: :routes

  validates :name, presence: true

  scope :ordered, -> { order(:name) }
end
