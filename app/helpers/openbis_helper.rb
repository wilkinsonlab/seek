module OpenbisHelper

  def format_openbis_properties properties
    return content_tag("span",:class=>"none_text"){"none found"} if properties.empty?
    properties.keys.collect do |key|
      content_tag("span",:class=>"openbis_metadata") do
        body = content_tag "b" do
          key.humanize
        end
        body.concat(": ")
        value = content_tag "em" do
          properties[key]
        end
        body.concat(value)
      end
    end.join("<br/>").html_safe

  end

end