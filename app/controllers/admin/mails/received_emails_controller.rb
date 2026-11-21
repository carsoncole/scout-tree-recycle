module Admin
  module Mails
    class ReceivedEmailsController < BaseController
      before_action :set_received_email, only: [ :show, :update, :mark_unread ]

      def index
        @pagy, @received_emails = pagy(::Mails::ReceivedEmail.recent_first)
      end

      def show
        @received_email.mark_read!
      end

      def update
        update_links(@received_email)
      end

      def mark_unread
        @received_email.mark_unread!
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
          format.html { redirect_to admin_mail_received_emails_path, notice: "Marked as unread." }
        end
      end

      private

      def set_received_email
        @received_email = ::Mails::ReceivedEmail.find(params[:id])
      end
    end
  end
end
