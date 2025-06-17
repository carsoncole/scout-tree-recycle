class Setting < ApplicationRecord
  AVAILABLE_TIME_ZONES = [
    "Eastern Time (US & Canada)",
    "Central Time (US & Canada)",
    "Mountain Time (US & Canada)",
    "Pacific Time (US & Canada)",
    "Alaska",
    "Hawaii",
    "UTC"
  ].freeze

  attribute :on_day_of_pickup_instructions, :string, default: "To prepare your tree for pick-up, remove all decorations and tinsel from your tree. Prior to pickup, place your tree in a visible location at the curb or where you indicated to us in your reservation. Your tree will be collected and recycled into mulch. We cannot take wreaths, flocked trees, or artificial trees. If we can not find your tree, we will try contacting you by SMS or phone call to make arrangements to attempt another pick-up."
  attribute :about_event_description, :string, default: "Tree Recycle is a community event where we collect trees and recycle them into mulch. This is our primary fundraiser for the year and all proceeds go to the Troop."
  attribute :reservations_closed_message, :string, default: "Stay tuned for when we open reservations again."
  attribute :time_zone, :string, default: "UTC"

  validates :organization_name, presence: true
  validates :default_city, :default_state, presence: true
  validates :event_pickup_start, :event_pickup_end, :event_sign_up_deadline, presence: { message: "date and time can't be blank" }
  validates :site_title, presence: true, if: ->(setting) { setting.organization_name.present? }
  validates :home_page_header, presence: true, if: ->(setting) { setting.organization_name.present? }
  validates :about_event_description, presence: true
  validates :on_day_of_pickup_instructions, presence: true
  validates :time_zone, inclusion: { in: AVAILABLE_TIME_ZONES }

  before_validation :set_defaults, on: :create

  def set_defaults
    return unless self.organization_name.present?
    self.site_title = self.organization_name.strip + " Tree Recycle"
    self.home_page_header = self.organization_name.strip + " Tree Recycle"
  end

  def self.instance
    first
  end
end
