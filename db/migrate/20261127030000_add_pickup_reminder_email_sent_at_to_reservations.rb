class AddPickupReminderEmailSentAtToReservations < ActiveRecord::Migration[8.1]
  def change
    add_column :reservations, :pickup_reminder_email_sent_at, :datetime
  end
end
