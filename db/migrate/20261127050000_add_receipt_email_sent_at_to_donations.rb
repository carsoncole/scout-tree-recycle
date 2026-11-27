class AddReceiptEmailSentAtToDonations < ActiveRecord::Migration[8.1]
  def change
    add_column :donations, :receipt_email_sent_at, :datetime
    remove_column :donations, :is_receipt_email_sent, :boolean
  end
end
