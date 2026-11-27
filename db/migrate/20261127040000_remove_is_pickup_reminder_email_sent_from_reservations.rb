class RemoveIsPickupReminderEmailSentFromReservations < ActiveRecord::Migration[8.1]
  def up
    remove_column :reservations, :is_pickup_reminder_email_sent, :boolean if column_exists?(:reservations, :is_pickup_reminder_email_sent)
  end

  def down
    add_column :reservations, :is_pickup_reminder_email_sent, :boolean, default: false, null: false unless column_exists?(:reservations, :is_pickup_reminder_email_sent)
  end
end
