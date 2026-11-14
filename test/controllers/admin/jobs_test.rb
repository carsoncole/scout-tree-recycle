require "test_helper"

class Admin::JobsTest < ActionDispatch::IntegrationTest
  test "redirects to sign in when not authenticated" do
    get "/admin/jobs"

    assert_redirected_to "http://www.example.com/admin/session/new"
  end

  test "renders the job dashboard when signed in" do
    sign_in

    get "/admin/jobs"

    assert_response :success
  end
end
