class SettingsMailer < AdminMailer
  def test_email(recipient)
    @setting = Setting.instance
    organization_name = @setting&.organization_name.presence || "Tree Recycle"

    mail to: recipient, subject: "Test email from #{organization_name}"
  end
end
