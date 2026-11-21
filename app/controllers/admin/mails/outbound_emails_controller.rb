module Admin
  module Mails
    class OutboundEmailsController < BaseController
      before_action :set_outbound_email, only: [ :show, :update ]

      def index
        @pagy, @outbound_emails = pagy(::Mails::OutboundEmail.recent_first)
      end

      def show
      end

      def new
        @to = params[:to].to_s
        @subject = ""
        @body = ""
        @email_alert = Setting.instance&.email_configuration_alert(purpose: "sending mail")
      end

      def create
        outbound = ::Mails::OutboundEmail.deliver!(
          :compose,
          to: params[:to],
          subject: params[:subject],
          body: params[:body]
        )
        if outbound
          redirect_to admin_mail_outbound_email_path(outbound), notice: "Email sent."
        else
          redirect_to admin_mail_outbound_emails_path, notice: "Email sent."
        end
      rescue ::Mails::OutboundEmail::NotSent => error
        render_compose(error.message)
      rescue StandardError => error
        Rails.error.report(error, handled: true, severity: :warning, context: { to: params[:to] })
        render_compose("Email could not be sent: #{error.message}")
      end

      def update
        update_links(@outbound_email)
      end

      private

      def set_outbound_email
        @outbound_email = ::Mails::OutboundEmail.find(params[:id])
      end

      def render_compose(message)
        @to = params[:to].to_s
        @subject = params[:subject].to_s
        @body = params[:body].to_s
        @email_alert = Setting.instance&.email_configuration_alert(purpose: "sending mail")
        flash.now[:alert] = message
        render :new, status: :unprocessable_entity
      end
    end
  end
end
