class AddIsReadToMailsReceivedEmails < ActiveRecord::Migration[8.1]
  def change
    add_column :mails_received_emails, :is_read, :boolean, null: false, default: false
    add_index :mails_received_emails, :is_read
  end
end
