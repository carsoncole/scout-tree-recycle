class Zone < ApplicationRecord
  has_many :routes, -> { order(:name) }, dependent: :nullify
  has_many :reservations, through: :routes

  validates :name, presence: true

  scope :ordered, -> { order(:name) }

  # Drivers covering this zone, grouped by the routes they drive. Preload
  # routes with :drivers before calling to avoid extra queries.
  def routes_by_driver
    routes.each_with_object({}) do |route, map|
      route.drivers.each { |driver| (map[driver] ||= []) << route }
    end
  end
end
