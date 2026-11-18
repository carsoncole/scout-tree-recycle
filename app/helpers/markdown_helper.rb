module MarkdownHelper
  LINK_PATTERN = /\[([^\]]+)\]\((https?:\/\/[^\s)]+)\)/.freeze
  BOLD_PATTERN = /\*\*(\S[^*]*?\S|\S)\*\*/.freeze
  ITALIC_PATTERN = /\*(\S[^*]*?\S|\S)\*/.freeze

  # Renders a small, safe subset of markdown: paragraphs separated by blank
  # lines, bullet lists ("- item"), **bold**, *italic*, and [links](http/https).
  # All input is HTML-escaped before conversion and link URLs must be http(s),
  # so stored content can never inject markup or script URLs.
  def basic_markdown(text, options = {})
    escaped = ERB::Util.html_escape(text.to_s)
    blocks = escaped.split(/\r?\n[ \t]*\r?\n+/).map(&:strip).reject(&:blank?)

    blocks.map { |block| markdown_block(block, options) }.join("\n").html_safe
  end

  private

  def markdown_block(block, options)
    lines = block.lines.map(&:strip)

    if lines.all? { |line| line.start_with?("- ") }
      items = lines.map { |line| markdown_tag(:li, markdown_inline(line.delete_prefix("- "))) }.join
      markdown_tag(:ul, items, options)
    else
      markdown_tag(:p, markdown_inline(lines.join(" ")), options)
    end
  end

  def markdown_inline(text)
    linked = text.gsub(LINK_PATTERN) do
      label = Regexp.last_match(1)
      url = Regexp.last_match(2)
      %(<a href="#{url}" class="text-sage-deep hover:text-ink dark:text-sage-deep-dark dark:hover:text-ink-dark" target="_blank" rel="noopener">#{label}</a>)
    end

    bolded = linked.gsub(BOLD_PATTERN) { markdown_tag(:strong, Regexp.last_match(1)) }
    bolded.gsub(ITALIC_PATTERN) { markdown_tag(:em, Regexp.last_match(1)) }
  end

  def markdown_tag(name, content, options = {})
    class_attribute = options[:class] ? %( class="#{options[:class]}") : ""

    "<#{name}#{class_attribute}>#{content}</#{name}>"
  end
end
