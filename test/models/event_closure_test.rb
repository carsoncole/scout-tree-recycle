require "test_helper"

class EventClosureTest < ActiveSupport::TestCase
  test "confirmed? accepts the close word regardless of case" do
    assert EventClosure.confirmed?("CLOSE")
    assert EventClosure.confirmed?(" close ")
    assert_not EventClosure.confirmed?("DELETE")
    assert_not EventClosure.confirmed?(nil)
  end

  test "preview separates copied reservations from unfinished ones" do
    closure = EventClosure.new

    assert_equal Reservation.migratable.count, closure.copied_count
    assert_equal Reservation.count - closure.copied_count, closure.discarded_count
    assert_includes closure.copied_status_labels, "Pending pickup"
    assert_includes closure.discarded_status_labels, "Reservation form"
    assert_not_includes closure.copied_status_labels, "Donation"
  end

  test "contacts past retention are counted unless a copied reservation replaces them" do
    replaced = Contact.create!(name: "Replaced", email: reservations(:routing_1).email, street: "1 Main")
    replaced.update_columns(created_at: 36.months.ago)
    removed = Contact.create!(name: "Old Gone", email: "old.gone@example.com", street: "2 Main")
    removed.update_columns(created_at: 36.months.ago)

    closure = EventClosure.new

    assert_equal 1, closure.contacts_removed_count
    assert_operator closure.contacts_replaced_count, :>=, 1
  end

  test "perform! copies eligible reservations, deletes every reservation, drops old contacts, and clears marketing dates" do
    copied_email = reservations(:routing_1).email
    unfinished_email = reservations(:reservation_form_minimum).email
    contact = contacts(:full)
    contact.update!(marketing_1_email_sent_at: Time.current, marketing_2_email_sent_at: Time.current)
    old = Contact.create!(name: "Old Gone", email: "old.gone@example.com", street: "2 Main")
    old.update_columns(created_at: 36.months.ago)

    EventClosure.new.perform!

    assert_equal 0, Reservation.count
    assert Contact.find_by(email: copied_email)
    assert_not Contact.find_by(email: unfinished_email)
    assert_nil Contact.find_by(email: "old.gone@example.com")
    contact.reload
    assert_nil contact.marketing_1_email_sent_at
    assert_nil contact.marketing_2_email_sent_at
  end
end
