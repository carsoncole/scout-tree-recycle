require "test_helper"

class MarketingEmailTemplateTest < ActiveSupport::TestCase
  setup do
    @template = marketing_email_templates(:marketing_email_1)
    @contact = contacts(:full)
    @assigns = MarketingEmailTemplate::Renderer.new(contact: @contact).assigns
  end

  test "is valid" do
    assert @template.valid?
  end

  test "requires a name, subject, and html body" do
    template = MarketingEmailTemplate.new

    assert_not template.valid?
    assert_includes template.errors[:name], "can't be blank"
    assert_includes template.errors[:subject], "can't be blank"
    assert_includes template.errors[:body_html], "can't be blank"
  end

  test "requires a unique name" do
    duplicate = @template.dup
    duplicate.name = @template.name

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "does not allow the name to change after creation" do
    assert_raises(ActiveRecord::ReadonlyAttributeError) do
      @template.update!(name: "renamed_template")
    end

    assert_equal "marketing_email_1", @template.reload.name
  end

  test "restricts names to slugs" do
    template = MarketingEmailTemplate.new(name: "Marketing Email 1", subject: "Subject", body_html: "<p>Body</p>")

    assert_not template.valid?
    assert_includes template.errors[:name], "may only contain lowercase letters, numbers, and underscores"
  end

  test "rejects invalid liquid syntax" do
    @template.body_html = "{% if contact.has_name %}Hello"

    assert_not @template.valid?
    assert_match "Liquid syntax error", @template.errors[:body_html].to_s
  end

  test "renders the subject and html body with liquid assigns" do
    assert_equal "Tree recycling January 6. Register today.", @template.render_subject(@assigns, source: :published)
    assert_includes @template.render_body_html(@assigns, source: :published), "Hi Susan Banks!"
    assert_includes @template.render_body_html(@assigns, source: :published), "Registration is now open for Tuesday, January 6."
  end

  test "renders the draft source separately from the published source" do
    @template.update!(subject: "Draft subject", body_html: "<p>Draft body for {{ contact.name }}</p>")

    assert_equal "Draft subject", @template.render_subject(@assigns, source: :draft)
    assert_equal "Tree recycling January 6. Register today.", @template.render_subject(@assigns, source: :published)
    assert_includes @template.render_body_html(@assigns, source: :draft), "Draft body for Susan Banks"
    assert_includes @template.render_body_html(@assigns, source: :published), "Support Troop 100"
  end

  test "publish copies draft content to the published version" do
    @template.update!(from: "marketing@example.com", subject: "New subject", body_html: "<p>New body</p>", body_text: "New body")

    assert @template.draft_changes?

    @template.publish!

    assert @template.published?
    assert_equal "marketing@example.com", @template.published_from
    assert_equal "New subject", @template.published_subject
    assert_equal "<p>New body</p>", @template.published_body_html
    assert_equal "New body", @template.published_body_text
    assert_not @template.draft_changes?
  end

  test "changing only the from address creates a pending draft change" do
    @template.update!(from: "new-from@example.com")

    assert @template.draft_changes?
    assert_not_equal @template.from, @template.published_from
  end

  test "unpublish removes the template from the published scope without deleting the snapshot" do
    @template.unpublish!

    assert_not @template.published?
    assert_not_includes MarketingEmailTemplate.published, @template
    assert_equal @template.subject, @template.published_subject
  end

  test "generates plain text from html when body text is blank" do
    @template.body_text = nil

    text = @template.render_body_text(@assigns, source: :draft)

    assert_includes text, "Support Troop 100! - Tree Recycling"
    assert_includes text, "Reserve My Tree Pickup (http://example.com/?contact_id="
  end

  test "generates plain text from simple html without paragraphs" do
    @template.body_text = nil
    @template.body_html = "<div>Hello {{ contact.first_name }}</div>"

    assert_equal "Hello Susan", @template.render_body_text(@assigns, source: :draft)
  end

  test "preview html inlines style blocks" do
    html = @template.preview_html(@assigns, source: :published)

    assert_includes html, "color: #123456"
    assert_not_includes html, "<style>"
  end

  test "install defaults creates and publishes missing default templates" do
    MarketingEmailTemplate.where(name: MarketingEmailTemplate.default_names).delete_all

    templates = MarketingEmailTemplate.install_defaults!

    assert_equal MarketingEmailTemplate.default_names.sort, templates.map(&:name).sort
    templates.each do |template|
      assert template.published?
      assert_includes template.body_html, "{{"
      assert_includes template.published_body_html, "{{"
      assert_not_includes template.body_html, "{{ images.logo }}"
      assert_not_includes template.body_html, "{{ images.reminder_logo }}"

      assert_nothing_raised do
        template.render_subject(@assigns, source: :published)
        template.render_body_html(@assigns, source: :published)
        template.render_body_text(@assigns, source: :published)
      end
    end
  end

  test "restore default content updates the draft without changing the published version" do
    published_subject = @template.published_subject
    published_body_html = @template.published_body_html
    @template.update!(subject: "Changed", body_html: "<p>Changed body</p>", description: "Changed")

    assert @template.restore_default_content!

    assert_equal MarketingEmailTemplate.default_definition(@template.name)[:subject], @template.subject
    assert_includes @template.body_html, "email-wrapper"
    assert_equal published_subject, @template.published_subject
    assert_equal published_body_html, @template.published_body_html
  end

  test "default templates cannot be identified as custom templates" do
    assert @template.default?
    assert_not marketing_email_templates(:draft_template).default?
  end

  test "lists only image files stored directly in the images directory" do
    filenames = MarketingEmailTemplate.available_images

    assert filenames.any?
    assert filenames.all? { |filename| File.file?(MarketingEmailTemplate::IMAGES_DIRECTORY.join(filename)) }
    assert filenames.all? { |filename| MarketingEmailTemplate::IMAGE_EXTENSIONS.include?(File.extname(filename).downcase) }
    assert_not_includes filenames, ".DS_Store"
    assert_not_includes filenames, ".keep"
  end

  test "generates liquid variable names from image filenames" do
    assert_equal "scouting_america_logo_stacked_bw_bc", MarketingEmailTemplate.image_key_for("Scouting America-Logo-stacked-bw-BC.png")
    assert_equal "scouting_america_logo_stacked_reversed_bc", MarketingEmailTemplate.image_key_for("Scouting_America_Logo_stacked_reversed_BC.png")
    assert_equal "tree", MarketingEmailTemplate.image_key_for("tree.png")
    assert_equal "image_2024_logo", MarketingEmailTemplate.image_key_for("2024-logo.png")
  end

  test "every root image has a unique liquid variable" do
    variables = MarketingEmailTemplate.image_variables

    assert_equal MarketingEmailTemplate.available_images, variables.values
    assert_equal variables.keys, variables.keys.uniq

    MarketingEmailTemplate.available_images.each do |filename|
      assert MarketingEmailTemplate.image_variable_for(filename).present?, "expected #{filename} to have a Liquid variable"
    end
  end

  test "includes image variables in the available template variables" do
    image = MarketingEmailTemplate.available_images.first
    variable_names = MarketingEmailTemplate.available_variables.map { |variable| variable[:name] }

    assert_includes variable_names, MarketingEmailTemplate.image_variable_for(image)
    assert_equal variable_names, variable_names.uniq
  end
end
