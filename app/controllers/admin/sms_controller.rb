class Admin::SmsController < Admin::BaseController
  def index
    @smses_by_phone = Sms.grouped_by_phone_for_index

    flash.now[:alert] = "SMS messaging is disabled. Enable SMS in Settings to send messages." unless Setting.instance.is_sms_enabled?
  end

  def mark_viewed
    phone = params[:phone]
    Sms.where(phone: phone, viewed: false).update_all(viewed: true)
    head :ok
  end

  def destroy
    phone = params[:phone]
    Sms.where(phone: phone).destroy_all
    redirect_to admin_sms_path, notice: "Conversation deleted successfully."
  end

  def create
    if Setting.instance.is_sms_enabled?
      @sms = Sms.new(sms_params)
      @sms.direction = :outgoing

      # Detect if the request is from the show page
      is_show_page = request.referer&.include?("/admin/sms/thread/")
      expanded = is_show_page
      show_page = is_show_page

      if @sms.save
        respond_to do |format|
          format.turbo_stream {
            if is_show_page
              @phone = @sms.phone
              @smses = Sms.where(phone: @phone).order(:created_at)
              flash.now[:notice] = "Message sent successfully."
              render turbo_stream: [
                turbo_stream.replace("sms-thread-#{@phone.gsub(/[^0-9]/, '')}",
                  partial: "admin/sms/thread", locals: { phone: @phone, smses: @smses, expanded: expanded, show_page: show_page }),
                turbo_stream.update("flash", partial: "shared/flash")
              ]
            else
              # For index page, just update the flash message since the broadcast will handle the conversation list
              flash.now[:notice] = "Message sent successfully."
              render turbo_stream: turbo_stream.update("flash", partial: "shared/flash")
            end
          }
          format.html {
            redirect_to admin_sms_path, notice: "Message sent successfully."
          }
        end
      else
        respond_to do |format|
          format.turbo_stream {
            if is_show_page
              @phone = @sms.phone
              @smses = Sms.where(phone: @phone).order(:created_at)
              @error = @sms.errors.full_messages.join(", ")
              flash.now[:alert] = "Failed to send message: #{@error}"
              render turbo_stream: [
                turbo_stream.replace("sms-thread-#{@phone.gsub(/[^0-9]/, '')}",
                  partial: "admin/sms/thread", locals: { phone: @phone, smses: @smses, error: @error, expanded: expanded, show_page: show_page }),
                turbo_stream.update("flash", partial: "shared/flash")
              ]
            else
              # For index page, just update the flash message
              flash.now[:alert] = "Failed to send message: #{@sms.errors.full_messages.join(', ')}"
              render turbo_stream: turbo_stream.update("flash", partial: "shared/flash")
            end
          }
          format.html {
            redirect_to admin_sms_path, alert: "Failed to send message: #{@sms.errors.full_messages.join(', ')}"
          }
        end
      end
    else
      is_show_page = request.referer&.include?("/admin/sms/thread/")
      expanded = is_show_page
      show_page = is_show_page
      respond_to do |format|
        format.turbo_stream {
          if is_show_page
            @phone = sms_params[:phone]
            @smses = Sms.where(phone: @phone).order(:created_at)
            @error = "SMS messaging is disabled. Enable SMS in Settings to send messages."
            flash.now[:alert] = @error
            render turbo_stream: [
              turbo_stream.replace("sms-thread-#{@phone.gsub(/[^0-9]/, '')}",
                partial: "admin/sms/thread", locals: { phone: @phone, smses: @smses, error: @error, expanded: expanded, show_page: show_page }),
              turbo_stream.update("flash", partial: "shared/flash")
            ]
          else
            # For index page, just update the flash message
            flash.now[:alert] = "SMS messaging is disabled. Enable SMS in Settings to send messages."
            render turbo_stream: turbo_stream.update("flash", partial: "shared/flash")
          end
        }
        format.html {
          redirect_to admin_sms_path, alert: "SMS messaging is disabled. Enable SMS in Settings to send messages."
        }
      end
    end
  end

  def show
    @phone = params[:phone]
    Sms.where(phone: @phone, viewed: false).update_all(viewed: true) # mark all as viewed
    @smses = Sms.where(phone: @phone).order(:created_at)
    @reservations = @smses.first&.reservations
  end

  private

  def sms_params
    params.require(:sms).permit(:phone, :body)
  end
end
