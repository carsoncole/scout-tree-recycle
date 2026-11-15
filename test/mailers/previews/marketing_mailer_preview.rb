# Preview all emails at http://localhost:3000/rails/mailers/marketing_mailer
class MarketingMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/marketing_mailer/marketing_email_1
  def marketing_email_1
    contact = preview_contact
    contact.update(marketing_1_email_sent_at: nil) if contact.persisted?
    MarketingMailer.with(contact_id: contact.id).marketing_email_1
  end

  # Preview this email at http://localhost:3000/rails/mailers/marketing_mailer/marketing_email_2
  def marketing_email_2
    contact = preview_contact
    contact.update(marketing_1_email_sent_at: 8.days.ago, marketing_2_email_sent_at: nil) if contact.persisted?
    MarketingMailer.with(contact_id: contact.id).marketing_email_2
  end

  private

  def preview_contact
    Contact.order(:created_at).first || MarketingEmailTemplate.sample_contact
  end
end
