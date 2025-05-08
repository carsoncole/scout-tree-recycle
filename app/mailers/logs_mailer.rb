class LogsMailer < ApplicationMailer
  def log_message_email
    @log = Log.find(params[:log_id])
    
    # Get all admin users
    admin_users = User.where(role: "admin")
    
    # Send email to all admin users
    admin_users.each do |admin|
      @user = admin
      mail(
        to: admin.email,
        subject: "New Log Entry: #{@log&.message&.truncate(50)}"
      )
    end
  end
end 