module OpenbisSamplesHelper
  def list_openbis_samples samples
    samples.collect do |sample|
      link_to(sample.title,sample)
    end.join(", ")

  end
end
