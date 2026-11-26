require "test_helper"

class ThankTest < ActiveSupport::TestCase
  FakeUpload = Struct.new(:content_type, :size) do
    def read
      "image-bytes"
    end
  end

  def build_thank(overrides = {})
    Thank.new({
      content: "Thanks to our friends at Acme Tree Farm.",
      image: "supporter-logo-bytes",
      image_content_type: "image/png"
    }.merge(overrides))
  end

  test "is valid with content, image, and content type" do
    assert build_thank.valid?
  end

  test "is valid without content" do
    thank = build_thank(content: nil)

    assert thank.valid?
    assert thank.save
    assert_nil thank.reload.content
  end

  test "is valid with an HTTP or HTTPS URL" do
    assert build_thank(url: "https://example.com/supporters").valid?
    assert build_thank(url: "http://example.com/supporters").valid?
  end

  test "is valid without a URL" do
    assert build_thank(url: nil).valid?
    assert build_thank(url: "").valid?
  end

  test "rejects a URL that is not HTTP or HTTPS" do
    thank = build_thank(url: "javascript:alert('unsafe')")

    assert_not thank.valid?
    assert_includes thank.errors[:url], "must be a valid HTTP or HTTPS URL"
  end

  test "requires an image on create" do
    thank = build_thank(image: nil, image_content_type: nil)

    assert_not thank.valid?
    assert_includes thank.errors[:image], "can't be blank"
  end

  test "does not require a new image on update" do
    thank = thanks(:one)

    assert thank.update(content: "Updated thanks")
    assert_equal "image/png", thank.image_content_type
  end

  test "stores an uploaded file in the image columns" do
    thank = Thank.new(content: "Thanks!", image_upload: FakeUpload.new("image/webp", 10))

    assert thank.valid?
    assert_equal "image-bytes", thank.image
    assert_equal "image/webp", thank.image_content_type
  end

  test "accepts each allowed image type" do
    Thank::ALLOWED_IMAGE_TYPES.each do |content_type|
      thank = build_thank(image_upload: FakeUpload.new(content_type, 10))

      assert thank.valid?, "expected #{content_type} to be accepted"
    end
  end

  test "rejects unsupported image types" do
    thank = build_thank(image_upload: FakeUpload.new("image/svg+xml", 10))

    assert_not thank.valid?
    assert_includes thank.errors[:image], "must be a PNG, JPEG, WebP, or GIF file"
  end

  test "rejects images larger than the limit" do
    thank = build_thank(image_upload: FakeUpload.new("image/png", Thank::MAX_IMAGE_BYTES + 1))

    assert_not thank.valid?
    assert_includes thank.errors[:image], "must be smaller than 5 MB"
  end

  test "recent orders newest first" do
    older = Thank.create!(content: "Older", image: "bytes", image_content_type: "image/png", created_at: 2.days.ago)
    newer = Thank.create!(content: "Newer", image: "bytes", image_content_type: "image/png", created_at: 1.day.ago)

    ordered = Thank.recent.to_a

    assert_operator ordered.index(newer), :<, ordered.index(older)
  end
end
