FactoryBot.define do
  factory :log do
    message { "wrong number of arguments (given 1, expected 0)" }
    severity { "error" }
    environment { "test" }
    handled { false }
    error_type { "ArgumentError" }
    backtrace { ["/path/to/file.rb:123:in `method_name'"] }
    context { { user: "admin@example.com" } }
  end
end
