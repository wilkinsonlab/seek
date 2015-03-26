class OpenbisSamplesController < ApplicationController

  include IndexPager
  include Seek::AssetsCommon


  before_filter :find_assets, :only=>[:index]
  before_filter :find_and_authorize_requested_item, :only=>[:show]

  def show
    @sample=@openbis_sample
  end
end
