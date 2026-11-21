module Admin
  module Mails
    class ReceivedEmailsController < BaseController
      before_action :set_received_email, only: [ :show, :update, :read, :destroy ]

      def index
        @pagy, @received_emails = pagy(::Mails::ReceivedEmail.recent_first)
      end

      def show
        @received_email.mark_read!
      end

      def update
        update_links(@received_email)
      end

      def read
        if ActiveModel::Type::Boolean.new.cast(params[:is_read])
          @received_email.mark_read!
        else
          @received_email.mark_unread!
        end

        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace(
                helpers.dom_id(@received_email),
                partial: "admin/mails/received_emails/row",
                locals: { email: @received_email }
              ),
              turbo_stream.replace(
                "mail_unread_count",
                partial: "admin/mails/unread_count",
                locals: { count: ::Mails::ReceivedEmail.unread.count }
              )
            ]
          end
          format.html do
            notice = @received_email.is_read? ? "Marked as read." : "Marked as unread."
            redirect_to admin_mail_received_emails_path, notice: notice
          end
        end
      end

      def destroy
        @received_email.destroy!
        redirect_to admin_mail_received_emails_path, notice: "Email deleted.", status: :see_other
      end

      private

      def set_received_email
        @received_email = ::Mails::ReceivedEmail.find(params[:id])
      end
    end
  end
end
