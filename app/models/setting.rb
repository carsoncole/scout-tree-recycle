class Setting < ApplicationRecord
  attribute :site_title, :string, default: 'Tree Recycle'
  attribute :home_page_header, :string, default: 'Tree Recycle'
  attribute :organization_name, :string, default: 'Troop 100'
  attribute :event_pickup, :datetime, default: '2099-01-06 08:00:00 -0800'
  attribute :event_pickup_end, :datetime, default: '2099-01-06 15:00:00 -0800'
  attribute :event_sign_up_deadline, :datetime, default: '2099-01-05 11:59:00 -0800'
  attribute :default_city, :string, default: 'Anytown'
  attribute :contact_name, :string, default: 'John Doe'
  attribute :contact_email, :string, default: 'john@example.com'
  attribute :contact_phone, :string, default: '206-555-1212'
  attribute :default_city, :string, default: 'Bainbridge Island'
  attribute :default_state, :string, default: 'Washington'
  attribute :country, :string, default: "United States"
  attribute :on_day_of_pickup_instructions, :string, default: 'To prepare your tree for pick-up, remove all decorations and tinsel from your tree. Prior to pickup, place your tree in a visible location at the curb or where you indicated to us in your reservation. Your tree will be collected and recycled into mulch. We cannot take wreaths, flocked trees, or artificial trees. If we can not find your tree, we will try contacting you by SMS or phone call to make arrangements to attempt another pick-up.'
  attribute :description, :string, default: 'Description...'
  attribute :email_from, :string, default: 'Anytown Tree Recycle <example@example.com>'

  validates :default_city, presence: true
  validates :event_pickup, presence: true
  validates :home_page_header, presence: true
  validates :event_pickup, :event_pickup_end, :event_sign_up_deadline, presence: true
  validates :organization_name, presence: true

  def self.instance
    first_or_create!
  end
end
