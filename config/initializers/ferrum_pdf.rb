# Configure FerrumPdf to locate a headless Chrome/Chromium executable in
# production environments where it may not be on PATH or may be installed
# under a non-default name (e.g. Render, Heroku buildpacks, Docker images).
browser_path = ENV["BROWSER_PATH"].presence ||
               ENV["GOOGLE_CHROME_BIN"].presence ||
               ENV["CHROME_BIN"].presence

unless browser_path
  browser_path = %w[
    /usr/bin/google-chrome-stable
    /usr/bin/google-chrome
    /usr/bin/chromium
    /usr/bin/chromium-browser
    /snap/bin/chromium
    /usr/bin/chrome
  ].find { |path| File.executable?(path) }
end

# Containers commonly require disabling Chrome's sandbox and /dev/shm usage.
docker_browser_options = { "no-sandbox" => nil, "disable-gpu" => nil, "disable-dev-shm-usage" => nil }

if browser_path.present?
  # Ferrum reads BROWSER_PATH when resolving the browser executable.
  ENV["BROWSER_PATH"] ||= browser_path

  if defined?(FerrumPdf)
    FerrumPdf.browser_path = browser_path if FerrumPdf.respond_to?(:browser_path=)

    if FerrumPdf.respond_to?(:configure)
      FerrumPdf.configure do |config|
        config.browser_path = browser_path if config.respond_to?(:browser_path=)

        if config.respond_to?(:browser_options) && config.respond_to?(:browser_options=)
          options = config.browser_options || {}
          options[:browser_path] = browser_path unless options[:browser_path] || options["browser_path"]
          docker_browser_options.each { |key, value| options[key] = value unless options.key?(key) || options.key?(key.to_sym) }
          config.browser_options = options
        end
      end
    end
  end
elsif defined?(FerrumPdf) && FerrumPdf.respond_to?(:configure)
  FerrumPdf.configure do |config|
    next unless config.respond_to?(:browser_options) && config.respond_to?(:browser_options=)

    options = config.browser_options || {}
    docker_browser_options.each { |key, value| options[key] = value unless options.key?(key) || options.key?(key.to_sym) }
    config.browser_options = options
  end
end
