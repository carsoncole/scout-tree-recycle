class RemoveStatusFromSms < ActiveRecord::Migration[8.0]
  def change
    remove_column :sms, :status, :string
  end
end
