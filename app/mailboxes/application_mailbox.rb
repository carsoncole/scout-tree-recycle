class ApplicationMailbox < ActionMailbox::Base
  # Direct messages and replies to automated mail both land in the archive.
  routing all: "mails/inbounds"
end
