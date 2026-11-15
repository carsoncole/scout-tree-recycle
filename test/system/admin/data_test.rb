require "application_system_test_case"

class Admin::DataTest < ApplicationSystemTestCase
  setup do
    sign_in_as(users(:admin), true)
  end

  test "visiting the data page" do
    visit admin_data_url
    assert_selector "h1", text: "Data"
    assert_text "Import reservations"
    assert_text "Export reservations"
    assert_link "System Logs"
  end

  test "importing a csv" do
    visit admin_data_url
    attach_file "CSV file", Rails.root.join("test/fixtures/files/reservations_import.csv")
    assert_selector "select[name='mapping[]']", count: 7
    selects = all("select[name='mapping[]']")
    selects[0].select("Name")
    selects[1].select("Email")
    selects[2].select("Street")
    selects[3].select("City")
    selects[4].select("State")
    selects[5].select("ZIP")
    selects[6].select("Status")
    click_button "Import Reservations CSV"
    assert_text "Imported 1 reservation"
  end
end
