require "test_helper"

class ContactTest < ActiveSupport::TestCase
  test "is valid" do
    assert contacts(:full).valid?
  end

  test "is invalid without email" do
    contact = contacts(:full)
    contact.email = nil
    assert_not contact.valid?
  end

  test "is invalid without name" do
    contact = contacts(:full)
    contact.name = nil
    assert_not contact.valid?
  end

  test "email is downcased" do
    contact = contacts(:full)
    contact.email = "JohnDoe@example.com"
    contact.save
    assert_equal "johndoe@example.com", contact.email
  end

  test "removing old contacts" do
    contact = contacts(:full)
    contact.update(created_at: (Setting.instance.contact_retention_months + 1).months.ago)
    Contact.remove_old_contacts!
    assert_not Contact.find_by(id: contact.id)
  end

  test "marketing email cooldown is active within the configured window" do
    contact = contacts(:full)
    contact.update(marketing_1_email_sent_at: 1.day.ago)

    assert contact.marketing_email_cooldown_active?

    Setting.instance.update(marketing_email_cooldown_days: 0)
    assert_not contact.marketing_email_cooldown_active?
  end

  test "clearing email flags" do
    contact = contacts(:full)
    contact.update(marketing_1_email_sent_at: 1.day.ago, marketing_2_email_sent_at: 1.day.ago)
    Contact.clear_email_flags!
    assert_nil contact.reload.marketing_1_email_sent_at
    assert_nil contact.marketing_2_email_sent_at
  end

  test "clearing a single marketing email send time" do
    contact = contacts(:full)
    contact.update(marketing_1_email_sent_at: 1.day.ago, marketing_2_email_sent_at: 2.days.ago)

    assert contact.clear_marketing_email!(1)

    assert_nil contact.reload.marketing_1_email_sent_at
    assert contact.marketing_2_email_sent_at.present?
  end

  test "does not clear a marketing email send time for an unknown email number" do
    contact = contacts(:full)
    contact.update(marketing_1_email_sent_at: 1.day.ago)

    assert_not contact.clear_marketing_email!(3)
    assert contact.marketing_1_email_sent_at.present?
  end
end
