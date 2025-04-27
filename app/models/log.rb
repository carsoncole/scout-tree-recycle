class Log < ApplicationRecord

  def self.report_error(error, context:, handled:, level:)
    Log.create(
      error: error,
      context: context,
      handled: handled,
      level: level
    )
  end
end