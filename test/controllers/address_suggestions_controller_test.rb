require "test_helper"

class AddressSuggestionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    configure_address_verification!
  end

  test "returns street-only suggestions" do
    suggestions = [
      LocationSearch::Suggestion.new(
        label: "123 Main Street, New York, NY 10001, United States",
        street: "123 Main Street",
        place_id: "place-123"
      )
    ]

    with_stubbed_address_suggestions(suggestions) do
      get address_suggestions_url, params: { query: "123 Main" }
    end

    assert_response :success
    payload = JSON.parse(response.body)
    suggestion = payload.fetch("suggestions").first

    assert_equal "123 Main Street", suggestion.fetch("street")
    assert_equal "123 Main Street, New York, NY 10001, United States", suggestion.fetch("label")
    assert_equal "place-123", suggestion.fetch("place_id")
    assert_not suggestion.key?("city")
    assert_not suggestion.key?("state")
    assert_not suggestion.key?("country")
  end

  test "returns no content when automatic routing is disabled" do
    Setting.instance.update!(is_routing_enabled: false)

    with_stubbed_address_suggestions([ LocationSearch::Suggestion.new(street: "1 Main St") ]) do
      get address_suggestions_url, params: { query: "1 Main" }
    end

    assert_response :no_content
  end

  test "returns no content for a short query" do
    with_stubbed_address_suggestions([ LocationSearch::Suggestion.new(street: "1 Main St") ]) do
      get address_suggestions_url, params: { query: "1" }
    end

    assert_response :no_content
  end

  test "returns no content when the location service fails" do
    error = LocationSearch::Error.new("Forbidden", status: 403)

    with_stubbed_address_suggestions_error(error) do
      get address_suggestions_url, params: { query: "123 Main" }
    end

    assert_response :no_content
  end
end
