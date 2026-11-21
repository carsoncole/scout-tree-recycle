class ContactsController < ApplicationController
  skip_forgery_protection only: :unsubscribe

  def unsubscribe
    @contact = Contact.find_by(id: params[:id])

    if request.post?
      process_unsubscribe
    elsif @contact.nil? || @contact.is_unsubscribed_from_marketing?
      redirect_to root_path, alert: "Your email has already been unsubscribed."
    end
  end

  private

  def process_unsubscribe
    @contact&.unsubscribe_from_marketing! unless @contact&.is_unsubscribed_from_marketing?

    if one_click_unsubscribe?
      head :ok
    elsif @contact
      redirect_to root_path, notice: "You have been successfully unsubscribed from our mailing list."
    else
      redirect_to root_path, alert: "Your email has already been unsubscribed."
    end
  end

  def one_click_unsubscribe?
    request.post? && params["List-Unsubscribe"].to_s == "One-Click"
  end
end
