module Mails
  # Drops attachments and inline images before Action Mailbox stores the raw
  # message. Text parts are kept. Unchanged text is returned as the original
  # source so it is not re-encoded.
  class InboundSource
    TEXT_TYPES = %w[text/plain text/html].freeze
    HEADER_NAMES = %w[from to cc bcc subject reply-to].freeze

    def self.strip(source)
      message = Mail.new(source)
      return source if unchanged?(message)

      rebuild(message).to_s
    rescue StandardError
      source
    end

    def self.unchanged?(message)
      if message.multipart?
        message.parts.all? { |part| unchanged?(part) }
      else
        keep_text?(message)
      end
    end

    def self.keep_text?(part)
      return false if part.attachment?
      return false if part.content_disposition.to_s.match?(/\Aattachment\b/i)

      type = part.mime_type.to_s.downcase
      type.blank? || TEXT_TYPES.include?(type)
    end

    def self.collect_text(message)
      if message.multipart?
        message.parts.flat_map { |part| collect_text(part) }
      elsif keep_text?(message)
        [ message ]
      else
        []
      end
    end

    def self.rebuild(message)
      kept = collect_text(message)
      clean = Mail.new
      copy_headers(message, clean)

      if kept.empty?
        clean.content_type = "text/plain; charset=UTF-8"
        clean.body = ""
      elsif kept.one?
        apply_text(clean, kept.first)
      else
        kept.each { |part| clean.add_part(text_part_from(part)) }
      end

      clean
    end

    def self.apply_text(message, part)
      message.content_type = part.content_type.presence || "text/plain; charset=UTF-8"
      message.body = part.body.decoded.to_s
    end

    def self.text_part_from(part)
      built = Mail::Part.new
      built.content_type = part.content_type.presence || "text/plain; charset=UTF-8"
      built.body = part.body.decoded.to_s
      built
    end

    def self.copy_headers(source, target)
      HEADER_NAMES.each do |name|
        field = source[name]
        target[name] = field.value if field
      end
      target.date = source.date if source.date
      target.message_id = source.message_id if source.message_id.present?
      reply_to = Mails::MessageId.bracket(source.in_reply_to)
      target.in_reply_to = reply_to if reply_to
      references = Mails::MessageId.bracket_list(source.references)
      target.references = references if references.present?
    end
    private_class_method :unchanged?, :keep_text?, :collect_text, :rebuild,
      :apply_text, :text_part_from, :copy_headers
  end
end
