#OPTIMIZE 404 Not Found page should have a message saying "If you started a reservation, please start again"
class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
end
