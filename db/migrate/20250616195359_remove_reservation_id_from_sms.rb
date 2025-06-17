class RemoveReservationIdFromSms < ActiveRecord::Migration[8.0]
  def change
    remove_column :sms, :reservation_id, :uuid
  end
end
