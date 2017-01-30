  module PersonRepresenter
    include Roar::JSON
    include Representable::Hash
    include Roar::Hypermedia

    include BaseRepresenter

    include StubRepresenter
  
    property :title  
    property :last_name
    property :first_name
    property :email
    property :web_page

    property :project_urls, as: :projects
    collection :institutions, :class => Institution, :extend => StubRepresenter
    collection :discipline_titles, as: :disciplines
    collection :expertise
#    collection :annotations
    
    def discipline_titles
      self.disciplines.collect { |d| d.title }
    end

    def project_urls
      self.projects.collect { |o| url_for o }
    end

 end

