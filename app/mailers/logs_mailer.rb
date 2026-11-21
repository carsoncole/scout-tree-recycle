class LogsMailer < ApplicationMailer
  def log_message_email
    @log = Log.find(params[:log_id])
    @user = User.find(params[:user_id])
    @context_json = context_json(@log.context)

    mail(
      to: @user.email,
      subject: "New Log Entry: #{subject_message(@log)}"
    )
  end

  private

  def subject_message(log)
    log.message.to_s.gsub(/[[:space:]]+/, " ").truncate(50)
  end

  # Context can contain strings that are still tagged as binary. JSON
  # generation raises on those, which used to drop the notification.
  def context_json(context)
    return if context.blank?

    JSON.pretty_generate(utf8_value(context))
  rescue StandardError
    context.to_s.encode("UTF-8", invalid: :replace, undef: :replace)
  end

  def utf8_value(value)
    case value
    when String
      value.dup.force_encoding("UTF-8").scrub
    when Hash
      value.to_h { |key, item| [ utf8_value(key.to_s), utf8_value(item) ] }
    when Array
      value.map { |item| utf8_value(item) }
    else
      value
    end
  end
end
