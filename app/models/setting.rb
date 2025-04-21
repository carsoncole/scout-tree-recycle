class Setting < ApplicationRecord
  attribute :site_title, :string, default: 'Tree Recycle'
  attribute :home_page_header, :string, default: 'Tree Recycle'
  attribute :default_city, :string, default: 'Anytown'
  attribute :contact_name, :string, default: 'John Doe'
  attribute :contact_email, :string, default: 'john@example.com'
  attribute :contact_phone, :string, default: '206-555-1212'
  attribute :on_day_of_pickup_instructions, :string, default: 'Pickup day instructions...'

  def self.instance
    first_or_create
  end
end
