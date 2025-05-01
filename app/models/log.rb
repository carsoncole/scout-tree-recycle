class Log < ApplicationRecord
  attribute :environment, :string, default: Rails.env
  attribute :severity, :string, default: 'info'
end
