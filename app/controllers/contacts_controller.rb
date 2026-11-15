class ContactsController < ApplicationController
  def unsubscribe
    @contact = Contact.find_by(id: params[:id])
    if @contact.nil?
      redirect_to root_path, alert: "Your email has already been unsubscribed."
    end
  end

  def destroy
    @contact = Contact.find_by(id: params[:id])
    if @contact&.destroy
      redirect_to root_path, notice: "You have been successfully unsubscribed from our mailing list."
    else
      redirect_to root_path, alert: "Unable to process your unsubscribe request. Please try again later."
    end
  end
end
