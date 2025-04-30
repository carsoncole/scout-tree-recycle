class PriorReservation < ApplicationRecord
  validates :name, :email, presence: true
  validates :email, uniqueness: true

  before_validation :downcase_email!

  def self.remove_old_prior_reservations!
    PriorReservation.where("created_at < ?", MINIMUM_MONTHS_BEFORE_PRIOR_RESERVATION_REMOVAL.months.ago).destroy_all
  end

  def self.clear_email_flags!
    PriorReservation.update_all(marketing_1_email_sent_at: nil, marketing_2_email_sent_at: nil)
  end
  

  private

  def downcase_email!
    self.email = self.email.downcase if self.email.present?
  end
end
