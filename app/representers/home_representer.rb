  module HomeRepresenter
    include Roar::JSON
    include Representable::Hash
    include Roar::Hypermedia
    include Roar::JSON::HAL::Links

    include BaseRepresenter

    link :url do root_url end
    link :current_user do url_for User.current_user.person end
    link :people do people_url end
    link :projects do projects_url end
    link :institutions do institutions_url end
    link :investigations do investigations_url end
    link :studies do studies_url end
    link :assays do assays_url end

    link :data_files do data_files_url end
    link :models do models_url end
    link :sops do sops_url end
    link :publications do publications_url end
    link :biosamples do biosamples_url end
    link :presentations do presentations_url end
    link :events do events_url end

 end
