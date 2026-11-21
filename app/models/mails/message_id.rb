module Mails
  # Message-IDs are stored without angle brackets so inbound In-Reply-To
  # values match outbound rows.
  module MessageId
    module_function

    def normalize(value)
      ids(value).first
    end

    def ids(value)
      Array(value).flatten.compact.flat_map { |item| item.to_s.scan(/[^<>\s]+/) }.uniq
    end

    def bracket(value)
      token = normalize(value)
      return if token.blank?

      "<#{token}>"
    end

    def bracket_list(values)
      ids(values).map { |token| "<#{token}>" }.join(" ")
    end
  end
end
