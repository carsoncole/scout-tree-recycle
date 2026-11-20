class Admin::SmsController < Admin::BaseController
  def index
    @smses_by_phone = Sms.grouped_by_phone_for_index

    flash.now[:alert] = "SMS messaging is disabled. Enable SMS in Settings to send messages." unless Setting.instance.is_sms_enabled?
  end

  def mark_viewed
    Sms.mark_viewed!(params[:phone])
    head :ok
  end

  def destroy
    phone = params[:phone]
    Sms.where(phone: phone).destroy_all
    redirect_to admin_sms_path, notice: "Conversation deleted successfully."
  end

  def create
    show_page = sms_show_page?

    unless Setting.instance.is_sms_enabled?
      render_sms_disabled(show_page)
      return
    end

    @sms = Sms.new(sms_params)
    @sms.direction = :outgoing
    @sms.user = Current.user

    if @sms.save
      render_sms_sent(show_page)
    else
      render_sms_failed(show_page)
    end
  end

  def show
    @phone = params[:phone]
    Sms.mark_viewed!(@phone)
    @smses = Sms.thread_for(@phone)
    @reservations = @smses.first&.reservations
  end

  private

  def sms_params
    params.require(:sms).permit(:phone, :body)
  end

  def sms_show_page?
    request.referer&.include?("/admin/sms/thread/")
  end

  def render_sms_sent(show_page)
    respond_to do |format|
      format.turbo_stream {
        flash.now[:notice] = "Message sent successfully."
        if show_page
          render turbo_stream: [
            turbo_stream.replace(Sms.thread_dom_id(@sms.phone), partial: "admin/sms/thread", locals: sms_thread_locals(@sms.phone, show_page: show_page)),
            turbo_stream.update("flash", partial: "shared/flash")
          ]
        else
          # Refresh the conversation list in the response as well as relying
          # on the cable broadcast, so the sent message is immediately visible
          # even if the websocket is unavailable.
          render turbo_stream: [
            turbo_stream.replace("sms_conversations",
              partial: "admin/sms/conversations",
              locals: { smses_by_phone: Sms.grouped_by_phone_for_index }),
            turbo_stream.update("flash", partial: "shared/flash")
          ]
        end
      }
      format.html { redirect_to admin_sms_path, notice: "Message sent successfully." }
    end
  end

  def render_sms_failed(show_page)
    respond_to do |format|
      format.turbo_stream {
        if show_page
          @error = @sms.errors.full_messages.join(", ")
          flash.now[:alert] = "Failed to send message: #{@error}"
          render turbo_stream: [
            turbo_stream.replace(Sms.thread_dom_id(@sms.phone), partial: "admin/sms/thread", locals: sms_thread_locals(@sms.phone, show_page: show_page, error: @error)),
            turbo_stream.update("flash", partial: "shared/flash")
          ]
        else
          flash.now[:alert] = "Failed to send message: #{@sms.errors.full_messages.join(', ')}"
          render turbo_stream: turbo_stream.update("flash", partial: "shared/flash")
        end
      }
      format.html { redirect_to admin_sms_path, alert: "Failed to send message: #{@sms.errors.full_messages.join(', ')}" }
    end
  end

  def render_sms_disabled(show_page)
    respond_to do |format|
      format.turbo_stream {
        if show_page
          @error = "SMS messaging is disabled. Enable SMS in Settings to send messages."
          flash.now[:alert] = @error
          render turbo_stream: [
            turbo_stream.replace(Sms.thread_dom_id(sms_params[:phone]), partial: "admin/sms/thread", locals: sms_thread_locals(sms_params[:phone], show_page: show_page, error: @error)),
            turbo_stream.update("flash", partial: "shared/flash")
          ]
        else
          flash.now[:alert] = "SMS messaging is disabled. Enable SMS in Settings to send messages."
          render turbo_stream: turbo_stream.update("flash", partial: "shared/flash")
        end
      }
      format.html { redirect_to admin_sms_path, alert: "SMS messaging is disabled. Enable SMS in Settings to send messages." }
    end
  end

  def sms_thread_locals(phone, show_page:, error: nil)
    @phone = phone
    @smses = Sms.thread_for(phone)
    locals = { phone: @phone, smses: @smses, expanded: show_page, show_page: show_page }
    locals[:error] = error if error
    locals
  end
end
