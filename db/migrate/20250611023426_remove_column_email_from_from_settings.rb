class RemoveColumnEmailFromFromSettings < ActiveRecord::Migration[8.0]
  def change
    remove_column :settings, :email_from, :string
  end
end
