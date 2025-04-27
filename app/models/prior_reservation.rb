class PriorReservation < ApplicationRecord
  validates :name, :email, presence: true
  validates :email, uniqueness: true

  before_validation :downcase_email!

  private

  def downcase_email!
    self.email = self.email.downcase if self.email.present?
  end
end
