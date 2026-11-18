require "test_helper"

class AdminHelperTest < ActionView::TestCase
  test "renders hash context as compact one-line JSON" do
    log = Log.new(context: { "user" => "admin@example.com", "ids" => [ 1, 2 ] })

    assert_equal '{"user":"admin@example.com","ids":[1,2]}', admin_log_context_json(log)
  end

  test "returns string contexts unchanged" do
    log = Log.new(context: "{\"user\" => \"admin@example.com\"}")

    assert_equal "{\"user\" => \"admin@example.com\"}", admin_log_context_json(log)
  end

  test "returns nil for blank context" do
    assert_nil admin_log_context_json(Log.new(context: {}))
    assert_nil admin_log_context_json(Log.new(context: nil))
  end
end
