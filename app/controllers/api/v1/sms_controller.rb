module Api
  module V1
    class SmsController < ActionController::API
      def reply
        Sms.create!(
          phone: params[:From],
          body: params[:Body],
          direction: "incoming"
        )
        head :ok
      rescue ActiveRecord::RecordInvalid
        head :unprocessable_entity
      end
    end
  end
end
