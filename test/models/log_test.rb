require "test_helper"

class LogTest < ActiveSupport::TestCase
  test "is valid" do
    assert logs(:one).valid?
  end
end
