require "test_helper"

class PublicControllerTest < ActionDispatch::IntegrationTest
    test "should get index" do
      get root_url
      assert_response :success
    end

    test "prefills the reservation form from a marketing preview link" do
      get root_url, params: {
        name: "Susan Banks",
        email: "susan@example.com",
        street: "123 Main St",
        mobile: "+11234567890"
      }

      assert_response :success
      assert_select "input[name=?][value=?]", "reservation[name]", "Susan Banks"
      assert_select "input[name=?][value=?]", "reservation[email]", "susan@example.com"
      assert_select "input[name=?][value=?]", "reservation[street]", "123 Main St"
      assert_select "input[name=?][value=?]", "reservation[mobile]", "+11234567890"
    end

    test "home header leaves out the reserve shortcut that other pages keep" do
      get root_url

      assert_response :success
      assert_select "header a", text: "Reserve a pickup", count: 0

      get about_url

      assert_response :success
      assert_select "header a[href=?]", "#{root_path}#reserve", text: "Reserve a pickup"
    end

    test "should get about" do
      get about_url
      assert_response :success
    end

    test "should display the configured thank you message on about" do
      Setting.instance.update!(thank_you_message: "Custom thanks from #{Setting.instance.organization_name}.")

      get about_url

      assert_response :success
      assert_includes response.body, "Custom thanks from Troop 100."
    end

    test "should link to thanks when thanks exist" do
      get about_url

      assert_select "a[href=?]", thanks_path, text: "See our thanks"
    end

    test "should not link to thanks when none exist" do
      Thank.delete_all

      get about_url

      assert_response :success
      assert_select "a[href=?]", thanks_path, text: "See our thanks", count: 0
    end

    test "should hide the thank you section when the message is cleared" do
      Setting.instance.update!(thank_you_message: "")

      get about_url

      assert_response :success
      assert_select "h3", text: "Thank you", count: 0
      assert_select "a[href=?]", thanks_path, text: "See our thanks", count: 0
      assert_not_includes response.body, Setting::DEFAULT_THANK_YOU_MESSAGE
    end

    test "should get privacy" do
      get privacy_url
      assert_response :success
    end

    test "should get credits" do
      get credits_url
      assert_response :success
    end

    test "should get index with reservations closed" do
      Setting.instance.update(is_reservations_open: false)
      get root_url
      assert_response :success
    end

    test "home page replaces the reservation form with the pickup notice" do
      Setting.instance.update!(
        is_pickup_notice_enabled: true,
        is_reservations_open: true,
        contact_name: "Alex Rivera",
        contact_email: "alex@example.com",
        contact_phone: "206-555-1212",
        contact_sms: "206-555-3434"
      )

      get root_url

      assert_response :success
      assert_select "title", text: /Pickups Underway/
      assert_select "h1", text: "Pickups are underway"
      assert_select "#pickup-notice" do
        assert_select "h2", text: "We're no longer taking reservations"
        assert_select "dt", text: "Message us (SMS)"
        assert_select "a[href=?]", "sms:206-555-3434", text: "206-555-3434"
        assert_select "dt", text: "Contact"
        assert_select "dd", text: "Alex Rivera"
        assert_select "a[href=?]", "mailto:alex@example.com", text: "alex@example.com"
        assert_select "a[href=?]", "tel:206-555-1212", text: "206-555-1212"
      end
      assert_equal [ "Contact", "Message us (SMS)", "Email", "Phone" ], css_select("#pickup-notice dt").map(&:text)
      assert_includes response.body, "currently picking up trees"
      assert_includes response.body, "issues with your reservation or tree pickup"
      assert_select "form", count: 0
      assert_select "a", text: "Reserve a pickup", count: 0
      assert_select ".site-deadline-badge", count: 0
      assert_includes response.body, "Remove decorations and tinsel"
      assert_not_includes response.body, "Reserve a pickup time for your tree."
    end

    test "pickup notice includes only the contact details that are set" do
      Setting.instance.update!(
        is_pickup_notice_enabled: true,
        contact_name: nil,
        contact_email: nil,
        contact_phone: nil,
        contact_sms: "206-555-3434"
      )

      get root_url

      assert_response :success
      assert_select "#pickup-notice" do
        assert_select "dt", text: "Message us (SMS)"
        assert_select "a[href=?]", "sms:206-555-3434", text: "206-555-3434"
        assert_select "dt", text: "Contact", count: 0
        assert_select "dt", text: "Email", count: 0
        assert_select "dt", text: "Phone", count: 0
      end
    end

    test "pickup notice replaces the reservations closed message" do
      Setting.instance.update!(
        is_pickup_notice_enabled: true,
        is_reservations_open: false,
        contact_name: nil,
        contact_email: nil,
        contact_phone: nil,
        contact_sms: nil
      )

      get root_url

      assert_response :success
      assert_select "#pickup-notice"
      assert_select "h2", text: "We're not taking reservations right now", count: 0
      assert_select "#pickup-notice dt", count: 0
      assert_not_includes response.body, Setting.instance.reservations_closed_message_text
    end

    test "about hides the reserve link while the pickup notice replaces the form" do
      Setting.instance.update!(is_pickup_notice_enabled: true, is_reservations_open: true)

      get about_url

      assert_response :success
      assert_select "a", text: "Reserve your pickup", count: 0
      assert_includes response.body, "Reservations are closed right now"
    end

    test "should use the configured home page image" do
      image = MarketingEmailTemplate.available_images.first
      Setting.instance.update!(home_page_image: image)

      get root_url

      assert_response :success
      assert_includes response.body, File.basename(image, ".*")
    end

    test "should include facebook open graph metadata on public pages" do
      get root_url

      assert_response :success
      title = css_select("title").first.text
      description = css_select("meta[name='description']").first["content"]

      assert_select "meta[property='og:title'][content=?]", title
      assert_select "meta[property='og:description'][content=?]", description
      assert_select "meta[property='og:type'][content='website']"
      assert_select "meta[property='og:url'][content=?]", "http://www.example.com/"
      assert_select "meta[property='og:site_name'][content=?]", Setting.instance.organization_name
      assert_select "meta[property='og:image'][content^='http'][content*=?]", "tree-4c-bc"
    end
end
