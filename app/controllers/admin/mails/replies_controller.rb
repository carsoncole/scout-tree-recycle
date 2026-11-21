module Admin
  module Mails
    class RepliesController < BaseController
      before_action :set_received_email

      def create
        outbound = ::Mails::OutboundEmail.deliver!(
          :reply,
          received_email: @received_email,
          body: params[:body]
        )
        if outbound
          redirect_to admin_mail_outbound_email_path(outbound), notice: "Reply sent."
        else
          redirect_to admin_mail_received_email_path(@received_email), notice: "Reply sent."
        end
      rescue ::Mails::OutboundEmail::NotSent => error
        redirect_to admin_mail_received_email_path(@received_email), alert: error.message
      rescue StandardError => error
        Rails.error.report(error, handled: true, severity: :warning, context: { received_email_id: @received_email.id })
        redirect_to admin_mail_received_email_path(@received_email), alert: "Reply could not be sent: #{error.message}"
      end

      private

      def set_received_email
        @received_email = ::Mails::ReceivedEmail.find(params[:received_email_id])
      end
    end
  end
end
