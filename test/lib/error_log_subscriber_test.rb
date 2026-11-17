require "test_helper"

class ErrorLogSubscriberTest < ActiveSupport::TestCase
  test "records an error with a JSON-safe context" do
    context = {
      controller: Object.new,
      nested: { ids: [ 1, 2 ] },
      when: :now
    }

    assert_difference -> { Log.count }, 1 do
      ErrorLogSubscriber.new.report(
        RuntimeError.new("boom"),
        handled: true,
        severity: :warning,
        context: context
      )
    end

    log = Log.order(:created_at).last
    assert_equal "RuntimeError", log.error_type
    assert_equal "boom", log.message
    assert_equal "Object", log.context["controller"]
    assert_equal({ "ids" => [ 1, 2 ] }, log.context["nested"])
    assert_equal "now", log.context["when"]
  end

  test "records an error whose context contains circular references" do
    context = {}
    context[:self] = context

    assert_difference -> { Log.count }, 1 do
      ErrorLogSubscriber.new.report(
        RuntimeError.new("circular"),
        handled: false,
        severity: :error,
        context: context
      )
    end
  end

  test "does not record errors raised by rails runner" do
    assert_no_difference -> { Log.count } do
      ErrorLogSubscriber.new.report(
        RuntimeError.new("console-only failure"),
        handled: false,
        severity: :error,
        context: {},
        source: "application.runner.railties"
      )
    end
  end

  test "records errors from application runtime sources" do
    assert_difference -> { Log.count }, 1 do
      ErrorLogSubscriber.new.report(
        RuntimeError.new("web failure"),
        handled: false,
        severity: :error,
        context: {},
        source: "application.action_dispatch"
      )
    end
  end

  test "does not raise when writing the log fails with a system stack error" do
    subscriber = ErrorLogSubscriber.new
    original_create = Log.method(:create)
    Log.define_singleton_method(:create) { |**| raise SystemStackError }

    assert_nothing_raised do
      subscriber.report(
        RuntimeError.new("boom"),
        handled: true,
        severity: :warning,
        context: {}
      )
    end
  ensure
    Log.define_singleton_method(:create, original_create) if original_create
  end

  test "does not report an error raised while it is already logging" do
    subscriber = ErrorLogSubscriber.new
    reports = 0
    original_create = Log.method(:create)

    Log.define_singleton_method(:create) do |**|
      reports += 1
      subscriber.report(
        RuntimeError.new("nested"),
        handled: true,
        severity: :warning,
        context: {}
      )
    end

    subscriber.report(
      RuntimeError.new("outer"),
      handled: true,
      severity: :warning,
      context: {}
    )

    assert_equal 1, reports
  ensure
    Log.define_singleton_method(:create, original_create) if original_create
  end
end
