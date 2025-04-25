class Driver < ApplicationRecord
  has_many :driver_routes, dependent: :destroy
  has_many :routes, through: :driver_routes

  validates :name, :mobile, presence: true
end
