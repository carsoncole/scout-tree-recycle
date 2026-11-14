class AddSmsQuickResponsesToSettings < ActiveRecord::Migration[8.1]
  DEFAULT_RESPONSES = [
    "Thank you! I'll let the Scouts know.",
    "Thanks for the update. I'll have them swing by again to pick up the tree.",
    "We are only picking up today, however I can see if we could swing by tomorrow.",
    "Thank you for your support! We appreciate it."
  ].join("\n")

  def change
    add_column :settings, :sms_quick_responses, :text, default: DEFAULT_RESPONSES
  end
end
