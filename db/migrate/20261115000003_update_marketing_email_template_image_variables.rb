class UpdateMarketingEmailTemplateImageVariables < ActiveRecord::Migration[8.1]
  REPLACEMENTS = {
    "{{ images.logo }}" => "{{ images.tree_scout }}",
    "{{ images.reminder_logo }}" => "{{ images.fleur_de_lis_2024_logo_4c_bc }}"
  }.freeze

  def up
    replace_image_variables(REPLACEMENTS)
  end

  def down
    replace_image_variables(REPLACEMENTS.invert)
  end

  private

  def replace_image_variables(replacements)
    execute <<~SQL
      UPDATE marketing_email_templates
      SET body_html = #{replace_sql("body_html", replacements)},
          published_body_html = #{replace_sql("published_body_html", replacements)}
    SQL
  end

  def replace_sql(column, replacements)
    replacements.reduce(column) do |expression, (from, to)|
      "REPLACE(#{expression}, #{connection.quote(from)}, #{connection.quote(to)})"
    end
  end
end
