require "base64"

# Discovers images that admins can reference from email templates and provides
# an inline data URI for previews.
class EmailImageLibrary
  DIRECTORY = Rails.root.join("app/assets/images")
  EXTENSIONS = %w[.png .jpg .jpeg .gif .svg .webp].freeze
  # Sent mail replaces this marker with a cid: URL after the HTML is rendered.
  # The marker uses the Liquid variable key so filenames with spaces stay intact.
  MARKER_PREFIX = "email-image:"

  class << self
    def available_images
      Dir.children(DIRECTORY)
        .select { |filename| File.file?(DIRECTORY.join(filename)) }
        .select { |filename| EXTENSIONS.include?(File.extname(filename).downcase) }
        .sort
    end

    def image_variables
      used_variables = []

      available_images.each_with_object({}) do |filename, variables|
        variable = unique_image_variable(image_key_for(filename), used_variables)
        used_variables << variable
        variables[variable] = filename
      end
    end

    def image_variable_for(filename)
      variable = image_variables.key(filename)
      "images.#{variable}" if variable
    end

    # Token placed in sent HTML. ApplicationMailer replaces it with a cid: URL
    # and attaches only the files whose markers survive rendering.
    def marker_for(filename)
      variable = image_variables.key(filename.to_s)
      return if variable.blank?

      "#{MARKER_PREFIX}#{variable}"
    end

    def image_key_for(filename)
      basename = File.basename(filename, File.extname(filename))
      key = basename.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/\A_+|_+\z/, "")
      key = "image" if key.blank?
      key = "image_#{key}" if key.match?(/\A\d/)
      key
    end

    def data_uri(filename)
      return "" if filename.blank?

      path = DIRECTORY.join(filename)
      return "" unless File.file?(path)

      mime_type = Marcel::MimeType.for(path, name: filename)
      "data:#{mime_type};base64,#{Base64.strict_encode64(File.binread(path))}"
    end

    def image_file?(filename)
      return false if filename.blank?

      path = DIRECTORY.join(filename)
      File.file?(path) && EXTENSIONS.include?(File.extname(filename).downcase)
    end

    private

    def unique_image_variable(variable, used_variables)
      candidate = variable
      suffix = 2
      while used_variables.include?(candidate)
        candidate = "#{variable}_#{suffix}"
        suffix += 1
      end
      candidate
    end
  end
end
