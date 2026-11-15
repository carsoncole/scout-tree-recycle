class Admin::ContactsController < Admin::BaseController
  before_action :set_contact, only: [ :edit, :update, :destroy, :clear_marketing_email_1, :clear_marketing_email_2 ]

  def new
    @contact = Contact.new
  end

  def create
    @contact = Contact.new(contact_params)

    if @contact.save
      redirect_to admin_marketing_index_path, notice: "Contact was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @contact.update(contact_params)
      redirect_to admin_marketing_index_path, notice: "Contact was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @contact.destroy
    redirect_to admin_marketing_index_path, notice: "Contact was successfully deleted."
  end

  def clear_marketing_email_1
    clear_marketing_email!(1)
  end

  def clear_marketing_email_2
    clear_marketing_email!(2)
  end

  def destroy_all
    if params[:confirmation].to_s.strip.casecmp?("DELETE")
      deleted_count = Contact.delete_all
      redirect_to admin_marketing_index_path,
        notice: deleted_count == 1 ? "1 contact has been deleted." : "#{deleted_count} contacts have been deleted."
    else
      redirect_to admin_marketing_index_path, alert: "Type DELETE to confirm deletion of all contacts."
    end
  end

  private

  def set_contact
    @contact = Contact.find(params[:id])
  end

  def contact_params
    params.require(:contact).permit(:name, :email, :mobile, :street)
  end

  def clear_marketing_email!(marketing_email)
    if @contact.clear_marketing_email!(marketing_email)
      redirect_to admin_marketing_index_path, notice: "Marketing email #{marketing_email} sent date was cleared."
    else
      redirect_to admin_marketing_index_path, alert: "Marketing email #{marketing_email} sent date could not be cleared."
    end
  end
end
