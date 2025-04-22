require "test_helper"

class ReservationsMailerTest < ActionMailer::TestCase
  test "send_new_reservation_email" do
    mail = ReservationsMailer.send_new_reservation_email
    assert_equal "Send new reservation email", mail.subject
    assert_equal [ "to@example.org" ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_match "Hi", mail.body.encoded
  end
end
