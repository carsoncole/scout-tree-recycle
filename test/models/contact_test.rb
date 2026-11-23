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

  test "first name uses the first word of the name" do
    assert_equal "Susan", contacts(:full).first_name
  end

  test "has name is false for blank and placeholder names" do
    contact = contacts(:full)
    assert contact.has_name?

    contact.name = "no name provided"
    assert_not contact.has_name?

    contact.name = nil
    assert_not contact.has_name?
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

  test "eligible for marketing email 1 when subscribed and not yet sent" do
    contact = contacts(:full)
    contact.update!(is_unsubscribed_from_marketing: false, marketing_1_email_sent_at: nil)

    assert contact.eligible_for_marketing_email?(1)

    contact.update!(marketing_1_email_sent_at: 1.day.ago)
    assert_not contact.eligible_for_marketing_email?(1)
  end

  test "not eligible for marketing emails when unsubscribed" do
    contact = contacts(:full)
    contact.unsubscribe_from_marketing!

    assert_not contact.eligible_for_marketing_email?(1)
    assert_not contact.eligible_for_marketing_email?(2)
  end

  test "eligible for marketing email 2 when subscribed and not yet sent" do
    contact = contacts(:full)
    contact.update!(marketing_2_email_sent_at: nil, marketing_1_email_sent_at: 1.day.ago)

    assert contact.eligible_for_marketing_email?(2)

    contact.update!(marketing_2_email_sent_at: 1.day.ago)
    assert_not contact.eligible_for_marketing_email?(2)
  end

  test "not eligible for marketing emails when email domain is test or example" do
    contact = contacts(:full)
    contact.update!(email: "jewel@orn.example", marketing_1_email_sent_at: nil, marketing_2_email_sent_at: nil)

    assert_not contact.eligible_for_marketing_email?(1)
    assert_not contact.eligible_for_marketing_email?(2)
    assert_not contact.marketable_email_domain?

    contact.update!(email: "person@subdomain.test")
    assert_not contact.marketable_email_domain?

    contact.update!(email: "person@valid.org")
    assert contact.marketable_email_domain?
  end

  test "blocked marketing email domain identifies test and example domains" do
    assert Contact.blocked_marketing_email_domain?("jewel@orn.example")
    assert Contact.blocked_marketing_email_domain?("user@test")
    assert Contact.blocked_marketing_email_domain?("user@example")
    assert Contact.blocked_marketing_email_domain?("user@foo.test")
    assert_not Contact.blocked_marketing_email_domain?("user@example.com")
    assert_not Contact.blocked_marketing_email_domain?("user@notexample.com")
  end

  test "with_marketable_email_domain excludes test and example domains" do
    blocked = Contact.create!(name: "Blocked", email: "blocked@orn.example")
    allowed = contacts(:full)

    assert_not_includes Contact.with_marketable_email_domain, blocked
    assert_includes Contact.with_marketable_email_domain, allowed
  end

  test "is subscribed to marketing by default" do
    contact = Contact.create!(name: "New Contact", email: "new-contact@example.com")
    assert_not contact.is_unsubscribed_from_marketing?
    assert_includes Contact.marketing_subscribed, contact
    assert_not_includes Contact.marketing_unsubscribed, contact
  end

  test "unsubscribing from marketing sets the flag" do
    contact = contacts(:full)

    contact.unsubscribe_from_marketing!

    assert contact.reload.is_unsubscribed_from_marketing?
    assert_not_includes Contact.marketing_subscribed, contact
    assert_includes Contact.marketing_unsubscribed, contact
  end

  test "search matches name, email, street, and mobile case-insensitively" do
    assert_includes Contact.search("susan"), contacts(:full)
    assert_includes Contact.search("TRIP.WILSON@EXAMPLE.COM"), contacts(:full)
    assert_includes Contact.search("123 main"), contacts(:full)
    assert_includes Contact.search("1234567890"), contacts(:full)
    assert_empty Contact.search("no-such-contact")
  end

  test "search with a blank query returns all contacts" do
    assert_equal Contact.count, Contact.search("").count
    assert_equal Contact.count, Contact.search("   ").count
    assert_equal Contact.count, Contact.search(nil).count
  end

  test "search combines with other scopes" do
    contacts(:full).update!(is_unsubscribed_from_marketing: true)

    assert_includes Contact.marketing_subscribed.search("trellis"), contacts(:no_mobile)
    assert_not_includes Contact.marketing_subscribed.search("susan"), contacts(:full)
  end

  test "to_csv exports every contact with the backup columns" do
    require "csv"

    csv = Contact.to_csv
    rows = CSV.parse(csv, headers: true)

    assert_equal Contact::EXPORT_FIELDS, rows.headers
    assert_equal Contact.count, rows.size
    assert_includes csv, contacts(:full).email
  end
end
