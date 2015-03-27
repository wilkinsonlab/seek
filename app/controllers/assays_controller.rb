class AssaysController < ApplicationController

  include DotGenerator
  include IndexPager
  include Seek::AssetsCommon

  before_filter :assays_enabled?

  before_filter :find_assets, :only=>[:index]
  before_filter :find_and_authorize_requested_item, :only=>[:edit, :update, :destroy, :show,:new_object_based_on_existing_one,:view_openbis,:add_openbis_stuff]

  before_filter :openbis_supported,:only=>[:view_openbis]

  #project_membership_required_appended is an alias to project_membership_required, but is necessary to include the actions
  #defined in the application controller
  before_filter :project_membership_required_appended, :only=>[:new_object_based_on_existing_one]

  include Seek::Publishing::PublishingCommon

  include Seek::BreadCrumbs

  def openbis_supported

    unless @assay.openbis_supported?
      flash[:error]="openBIS is not supported for this Assay. None of the related projects have been configured to point at an openBIS installation."
      return false
    end

  end

  def view_openbis

    if (params[:clear_cache])
      Rails.cache.clear
    end

    if (params[:wipe])
      disable_authorization_checks do
        @assay.openbis_samples.each do |os|
          os.destroy
        end
        @assay.openbis_samples.destroy_all
        @assay.data_files.each do |df|
          df.destroy
        end
        @assay.data_files.destroy_all
      end

    end

    p = @assay.openbis_project
    Seek::Openbis::ConnectionInfo.setup(p.openbis_username, p.openbis_password, p.openbis_endpoint)
    if params[:experiment_perm_id]
      @experiments=[Seek::Openbis::Experiment.new(params[:experiment_perm_id])]
    else
      @experiments = @assay.openbis_experiments.sort_by(&:modification_date).reverse
    end

    render :template=>"openbis/view_openbis"
  end

  def add_openbis_stuff

    sample_ids = params["samples"].try(:keys) || []
    dataset_ids = params["datasets"].try(:keys) || []

    datafiles = dataset_ids.collect do |id|
      begin
        ds = Seek::Openbis::Dataset.new(id)
        datafile = DataFile.load_from_openbis_dataset(ds)
        datafile.save!
        @assay.associate(datafile)

        @assay.save!
        datafile
      rescue Exception=>e
        Rails.logger.error(e)
        raise e if Rails.env=="development"
        nil
      end
    end.compact

    openbis_samples = sample_ids.collect do |id|
      begin
        zample = Seek::Openbis::Zample.new(id)
        sample = OpenbisSample.load_from_openbis_sample(zample)
        sample.assay_id=@assay.id
        sample.save!
        sample
      rescue Exception=>e
        Rails.logger.error(e)
        raise e if Rails.env=="development"
        nil
      end
    end.compact



    #link them together
    openbis_samples.each do |os|
      zample = os.internal_sample
      perm_ids = zample.datasets.select do |ds|
        dataset_ids.include?(ds.perm_id)
      end.collect(&:perm_id)
      os.data_files = datafiles.select{|df| perm_ids.include?(df.perm_id)}
      os.save!

    end

    redirect_to @assay

  end

  def new_object_based_on_existing_one
    @existing_assay =  Assay.find(params[:id])
    @assay = @existing_assay.clone_with_associations
    params[:data_file_ids]=@existing_assay.data_files.collect{|d|"#{d.id},None"}
    params[:related_publication_ids]= @existing_assay.publications.collect{|p| "#{p.id},None"}

    if @existing_assay.can_view?
      unless @assay.study.can_edit?
        @assay.study = nil
        flash.now[:notice] = "The #{t('study')} of the existing #{t('assays.assay')} cannot be viewed, please specify your own #{t('study')}! <br/>".html_safe
      end

      @existing_assay.data_files.each do |d|
        if !d.can_view?
          flash.now[:notice] << "Some or all #{t('data_file').pluralize} of the existing #{t('assays.assay')} cannot be viewed, you may specify your own! <br/>".html_safe
          break
        end
      end
      @existing_assay.sops.each do |s|
        if !s.can_view?
          flash.now[:notice] << "Some or all #{t('sop').pluralize} of the existing #{t('assays.assay')} cannot be viewed, you may specify your own! <br/>".html_safe
          break
        end
      end
      @existing_assay.models.each do |m|
        if !m.can_view?
          flash.now[:notice] << "Some or all #{t('model').pluralize} of the existing #{t('assays.assay')} cannot be viewed, you may specify your own! <br/>".html_safe
          break
        end
      end

      render :action=>"new"
    else
      flash[:error]="You do not have the necessary permissions to copy this #{t('assays.assay')}"
      redirect_to @existing_assay
    end


   end

  def new
    @assay=Assay.new
    @assay.create_from_asset = params[:create_from_asset]
    study = Study.find(params[:study_id]) if params[:study_id]
    @assay.study = study if params[:study_id] if study.try :can_edit?
    @assay_class=params[:class]

    #jump straight to experimental if modelling analysis is disabled
    @assay_class ||= "experimental" unless Seek::Config.modelling_analysis_enabled

    @assay.assay_class=AssayClass.for_type(@assay_class) unless @assay_class.nil?

    investigations = Investigation.all.select &:can_view?
    studies=[]
    investigations.each do |i|
      studies << i.studies.select(&:can_view?)
    end
    respond_to do |format|
      if investigations.blank?
         flash.now[:notice] = "No #{t('study')} and #{t('investigation')} available, you have to create a new #{t('investigation')} first before creating your #{t('study')} and #{t('assays.assay')}!"
      else
        if studies.flatten.blank?
          flash.now[:notice] = "No #{t('study')} available, you have to create a new #{t('study')} before creating your #{t('assays.assay')}!"
        end
      end

      format.html
      format.xml
    end
  end

  def edit
    respond_to do |format|
      format.html
      format.xml
    end
  end

  def create
    params[:assay_class_id] ||= AssayClass.for_type("experimental").id
    @assay = Assay.new(params[:assay])

    update_assay_organisms @assay, params

    @assay.owner=current_user.person

    @assay.policy.set_attributes_with_sharing params[:sharing], @assay.projects

    update_annotations(params[:tag_list], @assay) #this saves the assay
    update_scales @assay


    if @assay.save
      update_assets_linked_to_assay @assay, params

      update_relationships(@assay, params)

      #required to trigger the after_save callback after the assets have been associated
      @assay.save
      if @assay.create_from_asset =="true"
        render :action => :update_assays_list
      else
        respond_to do |format|
          flash[:notice] = "#{t('assays.assay')} was successfully created."
          format.html { redirect_to(@assay) }
          format.xml { render :xml => @assay, :status => :created, :location => @assay }
        end
      end
    else
      respond_to do |format|
        format.html { render :action => "new" }
        format.xml { render :xml => @assay.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    update_assay_organisms @assay, params

    update_annotations(params[:tag_list], @assay)
    update_scales @assay

    @assay.update_attributes(params[:assay])
    if params[:sharing]
      @assay.policy_or_default
      @assay.policy.set_attributes_with_sharing params[:sharing], @assay.projects
    end

    respond_to do |format|
      if @assay.save
        update_assets_linked_to_assay @assay, params

        update_relationships(@assay, params)

        @assay.save!

        flash[:notice] = "#{t('assays.assay')} was successfully updated."
        format.html { redirect_to(@assay) }
        format.xml { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml { render :xml => @assay.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update_assay_organisms assay,params
    organisms             = params[:assay_organism_ids] || []

    assay.assay_organisms = []
    Array(organisms).each do |text|
      o_id, strain,strain_id,culture_growth_type_text,t_id,t_title=text.split(",")
      culture_growth=CultureGrowthType.find_by_title(culture_growth_type_text)
      assay.associate_organism(o_id, strain_id, culture_growth,t_id,t_title)
    end
  end

  def update_assets_linked_to_assay assay,params
    sop_ids               = params[:assay_sop_ids] || []
    data_file_ids         = params[:data_file_ids] || []
    model_ids             = params[:model_ids] || []
    assay_assets_to_keep = [] #Store all the asset associations that we are keeping in this
    Array(data_file_ids).each do |text|
      id, r_type = text.split(",")
      d = DataFile.find(id)
      assay_assets_to_keep << assay.associate(d, RelationshipType.find_by_title(r_type)) if d.can_view?
    end
    Array(model_ids).each do |id|
      m = Model.find(id)
      assay_assets_to_keep << assay.associate(m) if m.can_view?
    end
    Array(sop_ids).each do |id|
      s = Sop.find(id)
      assay_assets_to_keep << assay.associate(s) if s.can_view?
    end
    #Destroy AssayAssets that aren't needed
    (assay.assay_assets - assay_assets_to_keep.compact).each { |a| a.destroy }
  end

  def show
    respond_to do |format|
      format.html
      format.xml
      format.rdf { render :template=>'rdf/show'}
    end
  end

  def update_types
    render :update do |page|
      page.replace_html "favourite_list", :partial=>"favourites/gadget_list"
    end
  end

end
