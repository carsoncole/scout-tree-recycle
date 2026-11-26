require "test_helper"

class SitemapsControllerTest < ActionDispatch::IntegrationTest
  test "lists all public content pages" do
    get sitemap_url(format: :xml)

    assert_response :success
    assert_equal "application/xml", response.media_type
    assert_equal [
      root_url,
      about_url,
      thanks_url,
      privacy_url,
      credits_url
    ], sitemap_urls
  end

  test "uses the configured site URL for sitemap links" do
    Setting.instance.update!(site_url: "https://trees.example.org:8443")

    get sitemap_url(format: :xml)

    assert_response :success
    assert_equal [
      "https://trees.example.org:8443/",
      "https://trees.example.org:8443/about",
      "https://trees.example.org:8443/thanks",
      "https://trees.example.org:8443/privacy",
      "https://trees.example.org:8443/credits"
    ], sitemap_urls
  end

  private

  def sitemap_urls
    document = Nokogiri::XML(response.body)
    document.xpath("//xmlns:url/xmlns:loc").map(&:text)
  end
end
