module Admin
  module Mails
    class ReceivedEmailsController < BaseController
      before_action :set_received_email, only: [ :show, :update ]

      def index
        @pagy, @received_emails = pagy(::Mails::ReceivedEmail.recent_first)
      end

      def show
      end

      def update
        update_links(@received_email)
      end

      private

      def set_received_email
        @received_email = ::Mails::ReceivedEmail.find(params[:id])
      end
    end
  end
end
