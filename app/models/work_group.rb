class WorkGroup < ActiveRecord::Base
  belongs_to :institution
  belongs_to :project
  has_many :group_memberships, dependent: :destroy
  has_many :people, through: :group_memberships

  validates :project, presence: { message: 'A project is required' }
  validates :institution, presence: { message: 'An institution is required' }

  include Seek::Rdf::ReactToAssociatedChange
  update_rdf_on_change :institution, :project

  def destroy
    if people.empty?
      super
    else
      fail Exception.new('You can not delete the ' + description + '. This Work Group has ' + people.size.to_s + ' people associated with it. Please disassociate first the people from this Work Group')
    end
  end

  def description
    project.title + ' at ' + institution.title
  end
end
