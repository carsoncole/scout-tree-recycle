class User < ApplicationRecord
  # How long an emailed account setup link stays usable.
  ACCOUNT_SETUP_TOKEN_TTL = 7.days

  has_secure_password
  has_many :sessions, dependent: :destroy

  generates_token_for :password_reset, expires_in: 15.minutes do
    password_salt&.last(10)
  end

  # Embeds the password salt and email, so the token stops working once the
  # password has been chosen or the account's email address has changed.
  generates_token_for :account_setup, expires_in: ACCOUNT_SETUP_TOKEN_TTL do
    [ password_salt&.last(10), email ]
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

  # Builds a user with a random, unusable password. The account holder picks
  # their own password through the emailed account setup link.
  def self.new_with_temporary_password(attributes = {})
    new(attributes.to_h.merge(password: SecureRandom.base58(32)))
  end

  def self.find_by_account_setup_token!(token)
    find_by_token_for!(:account_setup, token)
  end

  def account_setup_token
    generate_token_for(:account_setup)
  end

  # Sets a new password, requiring a non-blank value. Used by the reset and
  # account setup flows so an empty submission cannot silently succeed.
  def set_password(attributes)
    attributes = attributes.to_h.symbolize_keys

    if attributes[:password].blank?
      errors.add(:password, :blank)
      return false
    end

    update(attributes.slice(:password, :password_confirmation))
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
