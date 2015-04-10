module OpenbisHelper

  def format_openbis_properties properties
    return content_tag("span",:class=>"none_text"){"No additional metadata"} if properties.empty?
    properties.keys.sort.collect do |key|
      content_tag("div",:class=>"openbis-metadata") do
        body = content_tag "b" do
          key.humanize
        end
        body.concat(": ")
        value = content_tag "span",:class=>"openbis-metadata-value" do
          properties[key]
        end
        body.concat(value)
      end
    end.join().html_safe

  end

  def dataset_links datasets,experiment_datasets
    datasets.collect do |ds|
      if experiment_datasets.include?(ds)
        link_to(ds.code,"##{ds.perm_id}")
      else
        ds.code
      end
    end.join(", ").html_safe
  end

  def sample_links samples, experiment_samples
    samples.collect do |sample|
      if experiment_samples.include?(sample)
        link_to(sample.code,"##{sample.perm_id}")
      else
        sample.code
      end
    end.join(", ").html_safe
  end

end