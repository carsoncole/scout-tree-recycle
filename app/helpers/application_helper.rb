module ApplicationHelper
  def setting
    @setting ||= Setting.instance
  end
end
