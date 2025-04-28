module ApplicationHelper
  def setting
    Setting.instance
  end

  def email_footer
    Setting.instance.organization_name
  end
end
