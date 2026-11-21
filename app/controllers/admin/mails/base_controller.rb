module Admin
  module Mails
    class BaseController < Admin::BaseController
      private

      def update_links(email)
        messages = email.assign_links!(
          reservation_email: params[:reservation_email],
          contact_email: params[:contact_email]
        )
        if messages.any?
          redirect_to url_for(action: :show, id: email), alert: messages.to_sentence
        else
          redirect_to url_for(action: :show, id: email), notice: "Links updated."
        end
      end
    end
  end
end
