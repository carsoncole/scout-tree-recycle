require "test_helper"

class MarkdownHelperTest < ActionView::TestCase
  test "renders paragraphs separated by blank lines" do
    assert_equal "<p>First paragraph.</p>\n<p>Second paragraph.</p>",
                 basic_markdown("First paragraph.\n\nSecond paragraph.")
  end

  test "renders bullet lists" do
    assert_equal "<ul><li>One</li><li>Two</li></ul>", basic_markdown("- One\n- Two")
  end

  test "renders bold and italic text" do
    assert_equal "<p><strong>Bold</strong> and <em>italic</em> text.</p>",
                 basic_markdown("**Bold** and *italic* text.")
  end

  test "renders http links with site link styling" do
    assert_equal '<p><a href="https://example.com" class="text-sage-deep hover:text-ink dark:text-sage-deep-dark dark:hover:text-ink-dark" target="_blank" rel="noopener">Visit</a></p>',
                 basic_markdown("[Visit](https://example.com)")
  end

  test "renders inline formatting inside list items" do
    assert_equal "<ul><li><strong>Bold</strong> item</li><li>Plain item</li></ul>",
                 basic_markdown("- **Bold** item\n- Plain item")
  end

  test "leaves non-http links as plain text" do
    assert_equal "<p>[Bad](javascript:alert(1))</p>",
                 basic_markdown("[Bad](javascript:alert(1))")
  end

  test "escapes html in the source text" do
    assert_equal "<p>&lt;script&gt;alert(1)&lt;/script&gt;</p>",
                 basic_markdown("<script>alert(1)</script>")
  end

  test "applies the given class to top-level blocks" do
    assert_equal '<p class="last:mb-0">Text</p>', basic_markdown("Text", class: "last:mb-0")
    assert_equal '<ul class="last:mb-0"><li>Item</li></ul>', basic_markdown("- Item", class: "last:mb-0")
  end

  test "returns an empty string for blank input" do
    assert_equal "", basic_markdown("")
    assert_equal "", basic_markdown(nil)
  end
end
