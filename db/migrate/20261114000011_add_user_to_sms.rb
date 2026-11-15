class AddUserToSms < ActiveRecord::Migration[8.1]
  def change
    add_reference :sms, :user, foreign_key: true
  end
end
