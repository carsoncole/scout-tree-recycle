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
      rescue ActiveRecord::RecordInvalid => e
        Rails.error.report(e, handled: true, context: { params: params.to_unsafe_h })
        head :unprocessable_entity
      end
    end
  end
end
