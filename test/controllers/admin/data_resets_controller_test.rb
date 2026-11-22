require "test_helper"

class Admin::DataResetsControllerTest < ActionDispatch::IntegrationTest
  def with_failing_template_install
    original = MarketingEmailTemplate.method(:install_defaults!)
    MarketingEmailTemplate.define_singleton_method(:install_defaults!) { raise "boom" }
    yield
  ensure
    MarketingEmailTemplate.define_singleton_method(:install_defaults!, original) if original
  end

  test "should redirect unless signed in" do
    post admin_data_reset_path, params: { data_reset: { scope: "reservations" }, confirmation: "DELETE" }
    assert_redirected_to new_admin_session_path
  end

  test "non-admin users cannot delete or reset data" do
    sign_in users(:user)

    assert_no_changes -> { Reservation.count } do
      post admin_data_reset_path, params: { data_reset: { scope: "reservations" }, confirmation: "DELETE" }
    end

    assert_redirected_to admin_data_path
    assert_equal "You are not authorized to delete or reset data.", flash[:alert]
  end

  test "non-admin users cannot load sample data" do
    sign_in users(:user)

    assert_no_enqueued_jobs only: LoadSampleDataJob do
      post admin_data_reset_path, params: { data_reset: { scope: "sample_data" } }
    end

    assert_redirected_to admin_data_path
    assert_equal "You are not authorized to delete or reset data.", flash[:alert]
  end

  test "rejects an unknown scope" do
    sign_in users(:admin)

    post admin_data_reset_path, params: { data_reset: { scope: "users" }, confirmation: "RESET ALL" }

    assert_redirected_to admin_data_path
    assert_equal "Unknown data reset action.", flash[:alert]
  end

  test "requires the DELETE confirmation word for reservations" do
    sign_in users(:admin)

    assert_no_changes -> { Reservation.count } do
      post admin_data_reset_path, params: { data_reset: { scope: "reservations" }, confirmation: "RESET ALL" }
    end

    assert_redirected_to admin_data_path
    assert_equal "Type DELETE to confirm this destructive action.", flash[:alert]
  end

  test "requires the DELETE confirmation word for contacts" do
    sign_in users(:admin)

    assert_no_changes -> { Contact.count } do
      post admin_data_reset_path, params: { data_reset: { scope: "contacts" }, confirmation: "delete me" }
    end

    assert_redirected_to admin_data_path
    assert_equal "Type DELETE to confirm this destructive action.", flash[:alert]
  end

  test "admin can delete all reservations" do
    sign_in users(:admin)
    deleted_count = Reservation.count

    assert_difference -> { Log.where(log_type: "system").count }, 1 do
      post admin_data_reset_path, params: { data_reset: { scope: "reservations" }, confirmation: "DELETE" }
    end

    assert_redirected_to admin_data_path
    assert_equal 0, Reservation.count
    assert_match "#{deleted_count} reservations have been deleted", flash[:notice]
    assert_nil Donation.first&.reservation_id
  end

  test "admin can delete all contacts" do
    sign_in users(:admin)
    deleted_count = Contact.count

    assert_difference -> { Log.where(log_type: "system").count }, 1 do
      post admin_data_reset_path, params: { data_reset: { scope: "contacts" }, confirmation: "delete" }
    end

    assert_redirected_to admin_data_path
    assert_equal 0, Contact.count
    assert_match "#{deleted_count} contacts have been deleted", flash[:notice]
  end

  test "requires the full RESET ALL confirmation word" do
    sign_in users(:admin)

    assert_no_changes -> { Reservation.count } do
      post admin_data_reset_path, params: { data_reset: { scope: "all" }, confirmation: "RESET" }
    end

    assert_redirected_to admin_data_path
    assert_equal "Type RESET ALL to confirm this destructive action.", flash[:alert]
  end

  test "admin can reset all data and is signed out to first-run setup" do
    sign_in users(:admin)

    assert_difference -> { Log.where(log_type: "system").count }, 1 do
      post admin_data_reset_path, params: { data_reset: { scope: "all" }, confirmation: "RESET ALL" }
    end

    assert_redirected_to new_admin_setting_path
    assert_match "All data has been reset to defaults", flash[:notice]

    assert_equal 0, Reservation.count
    assert_equal 0, Contact.count
    assert_equal 0, User.count
    assert_equal 0, Setting.count
    assert_equal 0, Session.count
    assert_equal MarketingEmailTemplate.default_names.sort, MarketingEmailTemplate.pluck(:name).sort
    assert_equal ReservationEmailTemplate.default_names.sort, ReservationEmailTemplate.pluck(:name).sort
    assert_equal 0, Zone.count, "sample data should not be loaded by the reset"

    # The reset wiped the table, then recorded the event.
    log = Log.order(:created_at).last
    assert_includes log.message, "All data was reset to defaults"
    assert_equal users(:admin).email, log.context["user"]
  end

  test "admin can queue the sample data load without a typed confirmation word" do
    sign_in users(:admin)

    assert_enqueued_with(job: LoadSampleDataJob) do
      post admin_data_reset_path, params: { data_reset: { scope: "sample_data" } }
    end

    assert_redirected_to admin_data_path
    assert_match "queued", flash[:notice]
  end

  test "admin can load sample data in the background job" do
    sign_in users(:admin)

    assert_difference -> { Log.of_type("job").count }, 1 do
      perform_enqueued_jobs do
        post admin_data_reset_path, params: { data_reset: { scope: "sample_data" } }
      end
    end

    assert_redirected_to admin_data_path
    assert_operator Reservation.count, :>, 50
    assert_operator Contact.count, :>, 100
    assert Log.of_type("job").where(error_type: "LoadSampleDataJob").exists?
  end

  test "a failed reset rolls back and reports an error" do
    sign_in users(:admin)
    reservations_count = Reservation.count
    users_count = User.count

    with_failing_template_install do
      post admin_data_reset_path, params: { data_reset: { scope: "all" }, confirmation: "RESET ALL" }
    end

    assert_redirected_to admin_data_path
    assert_match "The data reset could not be completed", flash[:alert]
    assert_equal reservations_count, Reservation.count
    assert_equal users_count, User.count
  end
end
