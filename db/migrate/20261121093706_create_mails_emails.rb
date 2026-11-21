class CreateMailsEmails < ActiveRecord::Migration[8.1]
  def change
    create_table :mails_received_emails do |t|
      t.references :inbound_email, null: false, index: { unique: true },
        foreign_key: { to_table: :action_mailbox_inbound_emails }
      t.uuid :reservation_id
      t.uuid :contact_id
      t.string :message_id
      t.string :from_address
      t.text :to_addresses
      t.string :subject
      t.string :in_reply_to
      t.datetime :received_at
      t.timestamps
    end
    add_index :mails_received_emails, :message_id
    add_index :mails_received_emails, :in_reply_to
    add_index :mails_received_emails, :reservation_id
    add_index :mails_received_emails, :contact_id
    add_foreign_key :mails_received_emails, :reservations, column: :reservation_id, on_delete: :nullify
    add_foreign_key :mails_received_emails, :contacts, column: :contact_id, on_delete: :nullify

    create_table :mails_outbound_emails do |t|
      t.string :message_id, null: false
      t.string :from_address
      t.text :to_addresses
      t.string :subject
      t.datetime :sent_at
      t.uuid :reservation_id
      t.uuid :contact_id
      t.string :mailer
      t.string :action
      t.boolean :full_copy, null: false, default: false
      t.text :body
      t.string :in_reply_to
      t.text :references_header
      t.references :received_email, foreign_key: { to_table: :mails_received_emails, on_delete: :nullify }
      t.timestamps
    end
    add_index :mails_outbound_emails, :message_id, unique: true
    add_index :mails_outbound_emails, :reservation_id
    add_index :mails_outbound_emails, :contact_id
    add_index :mails_outbound_emails, :in_reply_to
    add_foreign_key :mails_outbound_emails, :reservations, column: :reservation_id, on_delete: :nullify
    add_foreign_key :mails_outbound_emails, :contacts, column: :contact_id, on_delete: :nullify
  end
end
