class AddThankYouMessageToSettings < ActiveRecord::Migration[8.1]
  DEFAULT_THANK_YOU_MESSAGE = "We want to say thank you to our community and to the supporters who make this fundraiser possible. Their generosity supports our Scouting program and the environment."

  def change
    add_column :settings, :thank_you_message, :text, default: DEFAULT_THANK_YOU_MESSAGE
  end
end
