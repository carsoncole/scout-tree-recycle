class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  generates_token_for :password_reset, expires_in: 15.minutes do
    password_salt&.last(10)
  end

  validates :role, presence: true, inclusion: { in: %w[admin user] }

  normalizes :email, with: ->(e) { e.strip.downcase }

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  def admin?
    role == "admin"
  end

  def user?
    role == "user"
  end

  # Updates this account's email and, when supplied, password.
  # Role is ignored. The current password is required.
  def update_profile(attributes)
    attributes = attributes.to_h.with_indifferent_access.except(:role)
    attributes[:password_challenge] = attributes[:password_challenge].to_s

    if attributes[:password].blank? && attributes[:password_confirmation].blank?
      attributes = attributes.except(:password, :password_confirmation)
    elsif attributes[:password].present?
      attributes[:password_confirmation] = attributes[:password_confirmation].to_s
    end

    update(attributes)
  end
end
