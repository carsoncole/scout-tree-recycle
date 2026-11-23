class AddressSuggestionsController < ApplicationController
  MIN_QUERY_LENGTH = 3

  # Street-only typeahead for the public reservation form. City, state, and
  # country are intentionally not part of the response so the typeahead can
  # never overwrite the app's configured pickup area.
  def index
    response.set_header("Cache-Control", "no-store")

    query = params[:query].to_s.strip
    return head :no_content if query.length < MIN_QUERY_LENGTH
    return head :no_content unless Setting.instance.address_verification_available?

    suggestions = LocationSearch.new(Setting.instance).autocomplete(query)

    render json: {
      suggestions: suggestions.map do |suggestion|
        {
          label: suggestion.label,
          street: suggestion.street,
          place_id: suggestion.place_id
        }
      end
    }
  rescue LocationSearch::Error => error
    Rails.logger.warn("Address suggestions failed: #{error.class}: #{error.message}")
    head :no_content
  end
end
