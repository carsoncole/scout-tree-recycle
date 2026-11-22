class MarketingEmailTemplate
  # Builds the Liquid assigns available to a marketing email template.
  class Renderer
    include EmailTemplateAssigns

    attr_reader :contact, :setting, :extra_assigns

    def initialize(contact: nil, setting: Setting.instance, extra_assigns: {})
      @contact = contact || MarketingEmailTemplate.sample_contact
      @setting = setting || Setting.new
      @extra_assigns = extra_assigns.stringify_keys
    end

    private

    def domain_assigns
      { "contact" => contact_assigns }
    end

    def contact_assigns
      {
        "id" => contact.id,
        "name" => contact.has_name? ? contact.name.to_s.strip : "",
        "first_name" => contact.has_name? ? contact.first_name : "",
        "email" => contact.email.to_s,
        "street" => contact.street.to_s,
        "mobile" => contact.mobile.to_s,
        "has_name" => contact.has_name?
      }
    end

    def url_assigns
      super.merge(
        "registration" => registration_url,
        "unsubscribe" => unsubscribe_url
      )
    end

    def registration_url
      if contact.id.present?
        url_helpers.root_url(contact_id: contact.id, **url_options)
      else
        url_helpers.root_url(**registration_prefill_params, **url_options)
      end
    end

    # Previews can use an unsaved sample contact. The reservation page reads
    # these fields when there is no contact id to look up.
    def registration_prefill_params
      {
        name: contact.name.to_s.strip.presence,
        email: contact.email.to_s.strip.presence,
        street: contact.street.to_s.strip.presence,
        mobile: contact.mobile.to_s.strip.presence
      }.compact
    end

    def unsubscribe_url
      return "" if contact.id.blank?

      url_helpers.unsubscribe_contact_url(contact.id, **url_options)
    end
  end
end
