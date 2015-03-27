class OpenbisSamplesController < ApplicationController

  include IndexPager
  include Seek::AssetsCommon


  before_filter :find_assets, :only=>[:index]
  before_filter :find_and_authorize_requested_item, :only=>[:show,:openbis_refresh]

  def show
    @sample=@openbis_sample
  end

  def openbis_refresh
    @openbis_sample.openbis_refresh
    redirect_to @openbis_sample
  end
end
