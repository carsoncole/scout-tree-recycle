module ApplicationHelper
  def setting
    @setting ||= Setting.instance
  end

  def surround_text(text, prefix = "", suffix = "")
    return "" if text.blank?

    "#{prefix}#{text}#{suffix}"
  end
end
