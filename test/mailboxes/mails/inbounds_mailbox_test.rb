require "test_helper"
require "action_mailbox/test_helper"

class Mails::InboundsMailboxTest < ActiveSupport::TestCase
  include ActionMailbox::TestHelper

  test "routing stores the raw message without attachments or a copied body" do
    mail = Mail.new
    mail.from = "Trip Wilson <trip.wilson@example.com>"
    mail.to = "support@example.com"
    mail.subject = "Question"
    mail.body = "Hello there"
    mail.add_file filename: "note.txt", content: "secret attachment bytes"

    inbound = receive_inbound_email_from_source(mail.to_s)
    received = Mails::ReceivedEmail.find_by!(inbound_email: inbound)
    raw = inbound.raw_email.download

    assert_predicate inbound, :delivered?
    assert_equal contacts(:full).id, received.contact_id
    assert_equal "trip.wilson@example.com", received.from_address
    assert_equal "Question", received.subject
    assert_not_includes Mails::ReceivedEmail.column_names, "body"
    assert_includes raw, "Hello there"
    assert_not_includes raw, "secret attachment bytes"
    assert_empty Mail.new(raw).attachments
    assert_operator ActiveStorageDB::File.count, :>, 0
    assert_equal "db", inbound.raw_email.blob.service_name
  end
end
