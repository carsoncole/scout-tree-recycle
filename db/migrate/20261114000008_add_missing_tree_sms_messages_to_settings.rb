class AddMissingTreeSmsMessagesToSettings < ActiveRecord::Migration[8.1]
  DEFAULT_MISSING_TREE_SMS = "Hi there! We're having trouble finding your tree for pick-up. Maybe it's not out, or you might not need it picked up anymore. Let us know by replying to this ASAP if you would like us to attempt another pick-up of your tree. Thanks!"
  DEFAULT_MISSING_TREE_SMS_FOLLOW_UP = "Hello, we are still having trouble finding your tree for pickup. Please check that it's out and reply to this message confirming it's location if you want us to try again. Thanks!"

  def change
    add_column :settings, :missing_tree_sms_message, :text, default: DEFAULT_MISSING_TREE_SMS
    add_column :settings, :missing_tree_sms_follow_up_message, :text, default: DEFAULT_MISSING_TREE_SMS_FOLLOW_UP
  end
end
