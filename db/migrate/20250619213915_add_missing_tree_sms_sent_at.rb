class AddMissingTreeSmsSentAt < ActiveRecord::Migration[8.0]
  def change
    add_column :reservations, :missing_tree_sms_sent_at, :datetime
  end
end
