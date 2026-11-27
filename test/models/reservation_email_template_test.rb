require "test_helper"

class ReservationEmailTemplateTest < ActiveSupport::TestCase
  setup do
    @template = reservation_email_templates(:new_reservation_email)
    @reservation = reservations(:pending_pickup_1)
    @assigns = ReservationEmailTemplate::Renderer.new(reservation: @reservation).assigns
  end

  test "is valid" do
    assert @template.valid?
  end

  test "requires a subject and html body" do
    template = ReservationEmailTemplate.new(name: "new_reservation_email")

    assert_not template.valid?
    assert_includes template.errors[:subject], "can't be blank"
    assert_includes template.errors[:body_html], "can't be blank"
  end

  test "restricts names to the supported reservation emails" do
    template = ReservationEmailTemplate.new(name: "custom_email", subject: "Subject", body_html: "<p>Body</p>")

    assert_not template.valid?
    assert_includes template.errors[:name], "is not included in the list"
  end

  test "restricts names to slugs" do
    template = ReservationEmailTemplate.new(name: "New Reservation Email", subject: "Subject", body_html: "<p>Body</p>")

    assert_not template.valid?
    assert_includes template.errors[:name], "may only contain lowercase letters, numbers, and underscores"
  end

  test "rejects invalid liquid syntax" do
    @template.body_html = "{% if reservation.has_name %}Hello"

    assert_not @template.valid?
    assert_match "Liquid syntax error", @template.errors[:body_html].to_s
  end

  test "requires a logo from the email image library" do
    @template.logo_image = "not-a-real-image.png"

    assert_not @template.valid?
    assert_includes @template.errors[:logo_image], "must be an image from the email image library"
  end

  test "default logo width matches the icon file" do
    header = File.binread(Rails.root.join("app/assets/images", ReservationEmailTemplate::DEFAULT_LOGO), 24)

    assert_equal 65, header.unpack1("@16N")
    assert_equal 65, ReservationEmailTemplate::LOGO_WIDTH
  end

  test "allows a blank logo" do
    @template.logo_image = nil

    assert @template.valid?
    assert_equal ReservationEmailTemplate::DEFAULT_LOGO, @template.logo_image_or_default
  end

  test "does not allow the name to change after creation" do
    assert_raises(ActiveRecord::ReadonlyAttributeError) do
      @template.update!(name: "cancelled_reservation_email")
    end

    assert_equal "new_reservation_email", @template.reload.name
  end

  test "renders the subject and html body with reservation assigns" do
    assert_equal "Your tree pickup is confirmed", @template.render_subject(@assigns, source: :published)

    body = @template.render_body_html(@assigns, source: :published)
    assert_includes body, "Tree pick-up scheduled"
    assert_includes body, "Dear Mary Jones"
    assert_includes body, "3:00pm"
    assert_includes body, "/reservations/#{@reservation.public_token}/edit"
    assert_includes body, "/reservations/#{@reservation.public_token}/donations/new"
    assert_includes body, "Troop 100"
  end

  test "renders the draft source separately from the published source" do
    @template.update!(subject: "Draft subject", body_html: "<p>Draft body for {{ reservation.name }}</p>")

    assert_equal "Draft subject", @template.render_subject(@assigns, source: :draft)
    assert_equal "Your tree pickup is confirmed", @template.render_subject(@assigns, source: :published)
    assert_includes @template.render_body_html(@assigns, source: :draft), "Draft body for Mary Jones"
  end

  test "publish copies draft content including the logo to the published version" do
    @template.update!(
      subject: "New subject",
      logo_image: "tree-scout.png",
      logo_alt: "New logo",
      body_html: "<p>New body</p>",
      body_text: "New body"
    )

    assert @template.draft_changes?

    @template.publish!

    assert @template.published?
    assert_equal "New subject", @template.published_subject
    assert_equal "tree-scout.png", @template.published_logo_image
    assert_equal "New logo", @template.published_logo_alt
    assert_equal "<p>New body</p>", @template.published_body_html
    assert_not @template.draft_changes?
  end

  test "changing only the logo creates a pending draft change" do
    @template.update!(logo_alt: "Changed logo alt")

    assert @template.draft_changes?
    assert_not_equal @template.logo_alt, @template.published_logo_alt
  end

  test "unpublish removes the template from the published scope without deleting the snapshot" do
    @template.unpublish!

    assert_not @template.published?
    assert_not_includes ReservationEmailTemplate.published, @template
    assert_equal @template.subject, @template.published_subject
  end

  test "renders the missing tree first notice and follow-up variants" do
    template = reservation_email_templates(:missing_tree_email)

    first_notice = ReservationEmailTemplate::Renderer.new(reservation: @reservation, follow_up: false).assigns
    follow_up = ReservationEmailTemplate::Renderer.new(reservation: @reservation, follow_up: true).assigns

    assert_equal "We could not find your tree", template.render_subject(first_notice, source: :published)
    assert_equal "Follow-up: We still cannot find your tree", template.render_subject(follow_up, source: :published)
    assert_includes template.render_body_html(first_notice, source: :published), "We visited your address today"
    assert_includes template.render_body_html(follow_up, source: :published), "We visited again today"
  end

  test "preview subject renders the missing tree variants" do
    template = reservation_email_templates(:missing_tree_email)

    assert_equal "We could not find your tree", template.preview_subject(follow_up: false)
    assert_equal "Follow-up: We still cannot find your tree", template.preview_subject(follow_up: true)
  end

  test "missing tree follow-up defaults to the reservation sent timestamp" do
    reservation = reservations(:pending_pickup_1)
    reservation.missing_tree_email_sent_at = 1.day.ago

    assigns = ReservationEmailTemplate::Renderer.new(reservation: reservation).assigns

    assert assigns.dig("reservation", "missing_tree_follow_up")
  end

  test "generates plain text from html when body text is blank" do
    @template.body_text = nil

    text = @template.render_body_text(@assigns, source: :draft)

    assert_includes text, "Tree pick-up scheduled"
    assert_includes text, "donate online (http://example.com/reservations/"
  end

  test "default content renders with reservation data" do
    definition = ReservationEmailTemplate.default_definition("new_reservation_email")
    template = ReservationEmailTemplate.find_or_initialize_by(name: "new_reservation_email")
    template.assign_attributes(definition.except(:name))
    template.published_subject = template.subject
    template.published_body_html = template.body_html
    template.published_body_text = template.body_text
    template.published_logo_image = template.logo_image
    template.published_logo_alt = template.logo_alt
    template.published_at = Time.current
    template.save!

    body = template.render_body_html(@assigns, source: :published)

    assert_includes body, "Tree pick-up scheduled"
    assert_includes body, "3:00pm"
    assert_includes body, "donate online"
    assert_includes body, "/reservations/#{@reservation.public_token}/edit"
    assert_not_includes body, "/reservations/#{@reservation.id}/edit"
    assert_equal "Your tree pickup is confirmed", template.render_subject(@assigns, source: :published)
  end

  test "donation receipt default omits the stripe receipt url" do
    definition = ReservationEmailTemplate.default_definition("donation_receipt_email")

    assert_not_includes definition[:body_html], "receipt_url"
    assert_not_includes definition[:body_html], "Receipt URL"
    assert_not_includes definition[:body_text], "receipt_url"
    assert_not_includes definition[:body_text], "Receipt URL"
  end

  test "install defaults creates and publishes missing default templates" do
    ReservationEmailTemplate.delete_all

    templates = ReservationEmailTemplate.install_defaults!

    assert_equal ReservationEmailTemplate::NAMES.sort, templates.map(&:name).sort
    templates.each do |template|
      assert template.published?
      assert_equal ReservationEmailTemplate::DEFAULT_LOGO, template.logo_image
      assert_equal ReservationEmailTemplate::DEFAULT_LOGO, template.published_logo_image
      assert_includes template.body_html, "{{"
      assert_includes template.published_body_html, "{{"

      assert_nothing_raised do
        template.render_subject(@assigns, source: :published)
        template.render_body_html(@assigns, source: :published)
        template.render_body_text(@assigns, source: :published)
      end
    end
  end

  test "restore default content updates the draft without changing the published version" do
    published_body = @template.published_body_html
    @template.update!(subject: "Changed", body_html: "<p>Changed body</p>", logo_alt: "Changed logo alt")

    assert @template.restore_default_content!

    assert_equal ReservationEmailTemplate.default_definition(@template.name)[:subject], @template.subject
    assert_includes @template.body_html, "email-heading"
    assert_equal published_body, @template.published_body_html
  end

  test "sample reservation provides preview data" do
    reservation = ReservationEmailTemplate.sample_reservation

    assert_equal "Susan Banks", reservation.name
    assert_equal "123 Main St", reservation.street
    assert reservation.pickup_notes.present?
  end

  test "available variables include reservation and image variables" do
    variable_names = ReservationEmailTemplate.available_variables.map { |variable| variable[:name] }
    image = EmailImageLibrary.available_images.first

    assert_includes variable_names, "reservation.name"
    assert_includes variable_names, "reservation.missing_tree_follow_up"
    assert_includes variable_names, "reservation.donation_received"
    assert_includes variable_names, "setting.pickup_instructions"
    assert_includes variable_names, "event.pickup_start_time_compact"
    assert_includes variable_names, "urls.edit_reservation"
    assert_includes variable_names, EmailImageLibrary.image_variable_for(image)
    assert_equal variable_names, variable_names.uniq
  end
end
