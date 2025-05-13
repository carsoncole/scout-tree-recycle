require "application_system_test_case"

class Admin::ReservationsRoutingStatusTest < ApplicationSystemTestCase
    setup do
        sign_in_as(users(:admin), true)
    end

    test "route column for reservation_form reservations" do
      visit admin_reservations_url
      within(page.find("tr", text: "steve.jobs@example.com")) do
        assert_text "Incomplete"
      end
    end

    test "route column for donation reservations" do
      visit admin_reservations_url
      within(page.find("tr", text: "lisa.mills@example.com")) do
        assert_text "Incomplete"
      end
    end

    test "route column for routing reservations" do
      visit admin_reservations_url
      within(page.find("tr", text: "icky.jones@example.com")) do
        assert_text "Pending"
      end
    end

    test "route column for pending pickup reservations" do
      visit admin_reservations_url
      within(page.find("tr", text: "mary.jones@example.com")) do
        assert_text "Route 1"
      end
    end

    test "route column for manually routed reservations" do
      visit admin_reservations_url
      within(page.find("tr", text: "trellis.wilson@example.com")) do
        assert_text "Manual"
      end
    end

    test "route column for routing reservations when routing is disabled" do
      Setting.instance.update(is_routing_enabled: false)
      visit admin_reservations_url
      within(page.find("tr", text: "icky.jones@example.com")) do
        assert_text "Manual"
      end
    end

    test "route column when status > pending_pickup and route exists" do
      visit admin_reservations_url
      within(page.find("tr", text: "bob.miurtha@example.com")) do
        assert_text "Route 2"
      end
    end

    test "route column when status > pending_pickup and route does not exist" do
      visit admin_reservations_url
      within(page.find("tr", text: "billy_carter@example.com")) do
        assert_text "Route Missing"
      end
    end
    
end