class Log < ApplicationRecord
  enum :log_level, { info: 1, warning: 2, error: 3 }
end
