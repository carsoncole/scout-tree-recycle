class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  attribute :time_zone, :string, default: "UTC"

  validates :role, presence: true, inclusion: { in: %w[admin user] }

  normalizes :email, with: ->(e) { e.strip.downcase }

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :time_zone, inclusion: { in: Setting::AVAILABLE_TIME_ZONES }

  def admin?
    role == "admin"
  end

  def user?
    role == "user"
  end
end
