module Mails
  # Prepended onto ActionMailbox::InboundEmail so the checksum and Message-ID
  # are computed from the text-only source.
  module StripInboundAttachments
    def create_and_extract_message_id!(source, **options)
      super(Mails::InboundSource.strip(source), **options)
    end
  end
end
