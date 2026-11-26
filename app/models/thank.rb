class Thank < ApplicationRecord
  ALLOWED_IMAGE_TYPES = %w[image/png image/jpeg image/webp image/gif].freeze
  MAX_IMAGE_BYTES = 5.megabytes

  # Virtual attribute used by the admin form. The uploaded file is copied into
  # the image and image_content_type columns before validation.
  attr_accessor :image_upload

  before_validation :store_image_upload

  validates :image, presence: true, on: :create
  validates :image_content_type, presence: true
  validate :image_upload_is_valid
  validate :url_must_be_http_or_https

  scope :recent, -> { order(created_at: :desc) }

  private

  def url_must_be_http_or_https
    return if url.blank?

    uri = URI.parse(url)
    return if uri.is_a?(URI::HTTP) && uri.host.present?

    errors.add(:url, "must be a valid HTTP or HTTPS URL")
  rescue URI::InvalidURIError
    errors.add(:url, "must be a valid HTTP or HTTPS URL")
  end

  def store_image_upload
    return unless image_upload.respond_to?(:read)

    self.image = image_upload.read
    self.image_content_type = image_upload.content_type
  end

  def image_upload_is_valid
    return unless image_upload.respond_to?(:read)

    unless ALLOWED_IMAGE_TYPES.include?(image_upload.content_type)
      errors.add(:image, "must be a PNG, JPEG, WebP, or GIF file")
    end

    if image_upload.size.to_i > MAX_IMAGE_BYTES
      errors.add(:image, "must be smaller than #{MAX_IMAGE_BYTES / 1.megabyte} MB")
    end
  end
end
