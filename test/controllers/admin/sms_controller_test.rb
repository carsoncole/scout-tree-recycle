require "test_helper"

class Admin::SmsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    sign_in
    get admin_sms_url
    assert_response :success
    assert_select "section#sms_conversations.admin-conversation-list", count: 1
  end

  test "should get index with disabled SMS" do
    Setting.instance.update(is_sms_enabled: false)
    sign_in
    get admin_sms_url
    assert_equal "SMS messaging is disabled. Enable SMS in Settings to send messages.", flash[:alert]
  end

  test "should create SMS" do
    sign_in
    Setting.instance.update(is_sms_enabled: true)
    post admin_sms_url, params: { sms: { phone: "+12069230400", body: "Hello, world!" } }
    assert_redirected_to admin_sms_url
    assert_equal "Message sent successfully.", flash[:notice]
  end

  test "should record the sent message so it survives a refresh" do
    sign_in
    Setting.instance.update(is_sms_enabled: true)

    assert_difference "Sms.count", 1 do
      post admin_sms_url, params: { sms: { phone: "+12069230400", body: "Recorded reply" } }
    end

    sms = Sms.order(:created_at).last
    assert_equal "outgoing", sms.direction
    assert_equal "+12069230400", sms.phone
    assert_equal "Recorded reply", sms.body
    assert_equal users(:admin), sms.user

    get admin_sms_thread_url(phone: "+12069230400")
    assert_response :success
    assert_includes response.body, "Recorded reply"
    assert_includes response.body, users(:admin).email
  end

  test "should attribute the message to the signed in user" do
    sign_in users(:admin_2)
    Setting.instance.update(is_sms_enabled: true)

    post admin_sms_url, params: { sms: { phone: "+12069230400", body: "From another admin" } }

    assert_equal users(:admin_2), Sms.order(:created_at).last.user
  end

  test "should show the sending user in the conversation thread" do
    sign_in users(:admin_2)
    Setting.instance.update(is_sms_enabled: true)

    post admin_sms_url,
      params: { sms: { phone: "+12069230400", body: "Named reply" } },
      headers: { "Referer" => admin_sms_thread_url(phone: "+12069230400") },
      as: :turbo_stream

    assert_response :success
    assert_includes response.body, users(:admin_2).email
  end

  test "should include the sent message in the index turbo stream response" do
    sign_in
    Setting.instance.update(is_sms_enabled: true)

    post admin_sms_url,
      params: { sms: { phone: "+12069230400", body: "Visible on index" } },
      as: :turbo_stream

    assert_response :success
    assert_includes response.body, "Visible on index"
    assert_includes response.body, "Sent by #{users(:admin).email}"
  end

  test "should link reservation names to their reservations on the inbox" do
    sign_in
    get admin_sms_url

    reservation = reservations(:address_verification_with_mobile)
    assert_select ".admin-conversation-reservations a.admin-badge--link[href=?]",
      admin_reservation_path(reservation),
      text: reservation.name
  end

  test "should show the associated reservation name on the conversation page" do
    sign_in
    get admin_sms_thread_url(phone: "+12064759823")

    assert_response :success
    reservation = reservations(:address_verification_with_mobile)
    assert_select ".admin-notice-title a[href=?]",
      admin_reservation_path(reservation),
      text: reservation.name
  end

  test "should delete conversation" do
    sign_in
    delete admin_sms_url, params: { phone: "+12069230400" }
    assert_redirected_to admin_sms_url
    assert_equal "Conversation deleted successfully.", flash[:notice]
    assert_equal 0, Sms.where(phone: "+12069230400").count
  end

  test "should make conversation viewed once show page is visited" do
    sign_in
    assert_equal 2, Sms.incoming.unviewed.where(phone: "+12069230400").count
    get admin_sms_thread_url(phone: "+12069230400")
    assert_equal 2, Sms.incoming.viewed.where(phone: "+12069230400").count
    assert_equal 0, Sms.incoming.unviewed.where(phone: "+12069230400").count
  end
end
