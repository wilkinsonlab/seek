require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  fixtures :projects, :institutions, :work_groups, :group_memberships, :people, :users, :publications, :assets, :organisms

  # checks that the dependent work_groups are destroyed when the project s
  def test_delete_work_groups_when_project_deleted
    p = Factory(:person).projects.first
    assert_equal 1, p.work_groups.size
    wg = p.work_groups.first

    wg.people = []
    wg.save!
    User.current_user = Factory(:admin).user
    assert_difference('WorkGroup.count', -1) do
      p.destroy
    end

    assert_equal nil, WorkGroup.find_by_id(wg.id)
  end

  test 'to_rdf' do
    object = Factory :project, web_page: 'http://www.sysmo-db.org',
                               organisms: [Factory(:organism), Factory(:organism)]
    Factory :data_file, projects: [object]
    Factory :data_file, projects: [object]
    Factory :model, projects: [object]
    Factory :sop, projects: [object]
    Factory :presentation, projects: [object]
    i = Factory :investigation, projects: [object]
    s = Factory :study, investigation: i
    Factory :assay, study: s
    wg = Factory :work_group, project: object
    Factory :group_membership, work_group: wg, person: Factory(:person)

    object.reload
    assert !object.people.empty?
    rdf = object.to_rdf
    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert reader.statements.count > 1
      assert_equal RDF::URI.new("http://localhost:3000/projects/#{object.id}"), reader.statements.first.subject
    end
  end

  test 'rdf with empty URI resource' do
    object = Factory :project, web_page: 'http://google.com'

    homepage_predicate = RDF::URI.new 'http://xmlns.com/foaf/0.1/homepage'
    found = false
    RDF::Reader.for(:rdfxml).new(object.to_rdf) do |reader|
      reader.each_statement do |statement|
        next unless statement.predicate == homepage_predicate
        found = true
        assert statement.valid?, 'statement is not valid'
        assert_equal RDF::URI.new('http://google.com'), statement.object
      end
    end
    assert found, "Didn't find homepage predicate"

    object.web_page = ''
    found = false
    RDF::Reader.for(:rdfxml).new(object.to_rdf) do |reader|
      reader.each_statement do |statement|
        next unless statement.predicate == homepage_predicate
        found = true

        assert statement.valid?, 'statement is not valid'
      end
    end
    assert !found, 'The homepage statement should have been skipped'
  end

  def test_avatar_key
    p = projects(:sysmo_project)
    assert_nil p.avatar_key
    assert p.defines_own_avatar?
  end

  test 'has_member' do
    person = Factory :person
    project = person.projects.first
    other_person = Factory :person
    assert project.has_member?(person)
    assert project.has_member?(person.user)
    assert !project.has_member?(other_person)
    assert !project.has_member?(other_person.user)
    assert !project.has_member?(nil)
  end

  def test_ordered_by_name
    assert Project.all.sort_by { |p| p.title.downcase } == Project.default_order || Project.all.sort_by(&:title) == Project.default_order
  end

  def test_title_trimmed
    p = Project.new(title: ' test project')
    disable_authorization_checks { p.save! }
    assert_equal('test project', p.title)
  end

  def test_set_credentials
    p = Project.new(title: 'test project')
    p.site_password = '12345'
    p.site_username = 'fred'
    disable_authorization_checks { p.save! }
    assert_not_nil p.site_credentials
  end

  def test_decrypt_credentials
    p = projects(:sysmo_project)
    p.site_password = '12345'
    p.site_username = 'fred'
    p.save!

    p = Project.find(p.id)
    assert_nil p.site_username, 'site username should be nil until requested'
    assert_nil p.site_password, 'site password should be nil until requested'

    p.decrypt_credentials
    assert_equal 'fred', p.site_username
    assert_equal '12345', p.site_password
  end

  def test_credentials_not_updated_unless_password_and_username_provided
    p = Project.new(title: 'fred')
    p.site_password = '12345'
    p.site_username = 'fred'
    disable_authorization_checks { p.save! }
    cred = p.site_credentials
    p = Project.find(p.id)
    assert_equal cred, p.site_credentials
    assert_nil p.site_password
    assert_nil p.site_username
    disable_authorization_checks { p.save! }
    assert_equal cred, p.site_credentials
    p = Project.find(p.id)
    assert_equal cred, p.site_credentials
  end

  def test_publications_association
    project = projects(:sysmo_project)

    assert_equal 3, project.publications.count

    assert project.publications.include?(publications(:one))
    assert project.publications.include?(publications(:pubmed_2))
    assert project.publications.include?(publications(:taverna_paper_pubmed))
  end

  def test_can_be_edited_by
    u = Factory(:project_administrator).user
    p = u.person.projects.first
    assert p.can_be_edited_by?(u), 'Project should be editable by user :project_administrator'

    p = Factory(:project)
    assert !p.can_be_edited_by?(u), 'other project should not be editable by project administrator, since it is not a project he administers'
  end

  test 'can be edited by programme adminstrator' do
    pa = Factory(:programme_administrator)
    project = pa.programmes.first.projects.first
    other_project = Factory(:project)

    assert project.can_be_edited_by?(pa.user)
    refute other_project.can_be_edited_by?(pa.user)
  end

  test 'can be edited by project member' do
    admin = Factory(:admin)
    person = Factory(:person)
    project = person.projects.first
    refute_nil project
    another_person = Factory(:person)

    assert project.can_be_edited_by?(person.user)
    refute project.can_be_edited_by?(another_person.user)

    User.with_current_user person.user do
      assert project.can_edit?
    end

    User.with_current_user another_person.user do
      refute project.can_edit?
    end
  end

  test 'can be administered by' do
    admin = Factory(:admin)
    project_administrator = Factory(:project_administrator)
    normal = Factory(:person)
    another_proj = Factory(:project)

    assert project_administrator.projects.first.can_be_administered_by?(project_administrator.user)
    assert !normal.projects.first.can_be_administered_by?(normal.user)

    assert !another_proj.can_be_administered_by?(normal.user)
    assert !another_proj.can_be_administered_by?(project_administrator.user)
    assert another_proj.can_be_administered_by?(admin.user)
  end

  test 'can be administered by programme administrator' do
    # programme administrator should be able to administer projects belonging to programme
    pa = Factory(:programme_administrator)
    project = pa.programmes.first.projects.first
    other_project = Factory(:project)

    assert project.can_be_administered_by?(pa.user)
    refute other_project.can_be_administered_by?(pa.user)
  end

  test 'update with attributes for project_administrator_ids ids' do
    person = Factory(:person)
    another_person = Factory(:person)

    project = person.projects.first
    refute_nil project

    another_person.add_to_project_and_institution(project, Factory(:institution))
    another_person.save!

    refute_includes project.project_administrators, person
    refute_includes project.project_administrators, another_person

    project.update_attributes(project_administrator_ids: [person.id.to_s])

    assert_includes project.project_administrators, person
    refute_includes project.project_administrators, another_person

    project.update_attributes(project_administrator_ids: [another_person.id.to_s])

    refute_includes project.project_administrators, person
    assert_includes project.project_administrators, another_person

    # cannot change to a person from another project
    person_in_other_project = Factory(:person)
    project.update_attributes(project_administrator_ids: [person_in_other_project.id.to_s])

    refute_includes project.project_administrators, person
    refute_includes project.project_administrators, another_person
    refute_includes project.project_administrators, person_in_other_project
  end

  test 'update with attributes for gatekeeper ids' do
    person = Factory(:person)
    another_person = Factory(:person)

    project = person.projects.first
    refute_nil project

    another_person.add_to_project_and_institution(project, Factory(:institution))
    another_person.save!

    refute_includes project.asset_gatekeepers, person
    refute_includes project.asset_gatekeepers, another_person

    project.update_attributes(asset_gatekeeper_ids: [person.id.to_s])

    assert_includes project.asset_gatekeepers, person
    refute_includes project.asset_gatekeepers, another_person

    project.update_attributes(asset_gatekeeper_ids: [another_person.id.to_s])

    refute_includes project.asset_gatekeepers, person
    assert_includes project.asset_gatekeepers, another_person

    # 2 at once
    project.update_attributes(asset_gatekeeper_ids: [person.id.to_s, another_person.id.to_s])
    assert_includes project.asset_gatekeepers, person
    assert_includes project.asset_gatekeepers, another_person

    # cannot change to a person from another project
    person_in_other_project = Factory(:person)
    project.update_attributes(asset_gatekeeper_ids: [person_in_other_project.id.to_s])

    refute_includes project.asset_gatekeepers, person
    refute_includes project.asset_gatekeepers, another_person
    refute_includes project.asset_gatekeepers, person_in_other_project
  end

  test 'update with attributes for pal ids' do
    person = Factory(:person)
    another_person = Factory(:person)

    project = person.projects.first
    refute_nil project

    another_person.add_to_project_and_institution(project, Factory(:institution))
    another_person.save!

    refute_includes project.pals, person
    refute_includes project.pals, another_person

    project.update_attributes(pal_ids: [person.id.to_s])

    assert_includes project.pals, person
    refute_includes project.pals, another_person

    project.update_attributes(pal_ids: [another_person.id.to_s])

    refute_includes project.pals, person
    assert_includes project.pals, another_person

    # cannot change to a person from another project
    person_in_other_project = Factory(:person)
    project.update_attributes(pal_ids: [person_in_other_project.id.to_s])

    refute_includes project.pals, person
    refute_includes project.pals, another_person
    refute_includes project.pals, person_in_other_project
  end

  test 'update with attributes for asset housekeeper ids' do
    person = Factory(:person)
    another_person = Factory(:person)

    project = person.projects.first
    refute_nil project

    another_person.add_to_project_and_institution(project, Factory(:institution))
    another_person.save!

    refute_includes project.asset_housekeepers, person
    refute_includes project.asset_housekeepers, another_person

    project.update_attributes(asset_housekeeper_ids: [person.id.to_s])

    assert_includes project.asset_housekeepers, person
    refute_includes project.asset_housekeepers, another_person

    project.update_attributes(asset_housekeeper_ids: [another_person.id.to_s])

    refute_includes project.asset_housekeepers, person
    assert_includes project.asset_housekeepers, another_person

    # 2 at once
    project.update_attributes(asset_housekeeper_ids: [person.id.to_s, another_person.id.to_s])
    assert_includes project.asset_housekeepers, person
    assert_includes project.asset_housekeepers, another_person

    # cannot change to a person from another project
    person_in_other_project = Factory(:person)
    project.update_attributes(asset_housekeeper_ids: [person_in_other_project.id.to_s])

    refute_includes project.asset_housekeepers, person
    refute_includes project.asset_housekeepers, another_person
    refute_includes project.asset_housekeepers, person_in_other_project
  end

  def test_update_first_letter
    p = Project.new(title: 'test project')
    disable_authorization_checks { p.save! }
    assert_equal 'T', p.first_letter
  end

  def test_valid
    p = projects(:one)

    p.web_page = nil
    assert p.valid?

    p.web_page = ''
    assert p.valid?

    p.web_page = 'sdfsdf'
    assert !p.valid?

    p.web_page = 'http://google.com'
    assert p.valid?

    p.web_page = 'https://google.com'
    assert p.valid?

    p.web_page = 'http://google.com/fred'
    assert p.valid?

    p.web_page = 'http://google.com/fred?param=bob'
    assert p.valid?

    p.web_page = 'http://www.mygrid.org.uk/dev/issues/secure/IssueNavigator.jspa?reset=true&mode=hide&sorter/order=DESC&sorter/field=priority&resolution=-1&pid=10051&fixfor=10110'
    assert p.valid?

    p.wiki_page = nil
    assert p.valid?

    p.wiki_page = ''
    assert p.valid?

    p.wiki_page = 'sdfsdf'
    assert !p.valid?

    p.wiki_page = 'http://google.com'
    assert p.valid?

    p.wiki_page = 'https://google.com'
    assert p.valid?

    p.wiki_page = 'http://google.com/fred'
    assert p.valid?

    p.wiki_page = 'http://google.com/fred?param=bob'
    assert p.valid?

    p.wiki_page = 'http://www.mygrid.org.uk/dev/issues/secure/IssueNavigator.jspa?reset=true&mode=hide&sorter/order=DESC&sorter/field=priority&resolution=-1&pid=10051&fixfor=10110'
    assert p.valid?

    p.title = nil
    assert !p.valid?

    p.title = ''
    assert !p.valid?

    p.title = 'fred'
    assert p.valid?
  end

  test 'test uuid generated' do
    p = projects(:one)
    assert_nil p.attributes['uuid']
    p.save
    assert_not_nil p.attributes['uuid']
  end

  test "uuid doesn't change" do
    x = projects(:one)
    x.save
    uuid = x.attributes['uuid']
    x.save
    assert_equal x.uuid, uuid
  end

  test 'Should order Latest list of projects by updated_at' do
    project1 = Factory(:project, title: 'C', updated_at: 2.days.ago)
    project2 = Factory(:project, title: 'B', updated_at: 1.days.ago)

    latest_projects = Project.paginate_after_fetch([project1, project2], page: 'latest')
    assert_equal project2, latest_projects.first
  end

  test 'can_delete?' do
    project = Factory(:project)

    # none-admin can not delete
    user = Factory(:user)
    assert !user.is_admin?
    assert project.work_groups.collect(&:people).flatten.empty?
    assert !project.can_delete?(user)

    # can not delete if workgroups contain people
    user = Factory(:admin).user
    assert user.is_admin?
    project = Factory(:project)
    work_group = Factory(:work_group, project: project)
    a_person = Factory(:person, group_memberships: [Factory(:group_membership, work_group: work_group)])
    assert !project.work_groups.collect(&:people).flatten.empty?
    assert !project.can_delete?(user)

    # can delete if admin and workgroups are empty
    work_group.group_memberships.delete_all
    assert project.work_groups.reload.collect(&:people).flatten.empty?
    assert user.is_admin?
    assert project.can_delete?(user)
  end

  test 'gatekeepers' do
    User.with_current_user(Factory(:admin)) do
      person = Factory(:person_in_multiple_projects)
      assert_equal 3, person.projects.count
      proj1 = person.projects.first
      proj2 = person.projects.last
      person.is_asset_gatekeeper = true, proj1
      person.save!

      assert proj1.asset_gatekeepers.include?(person)
      assert !proj2.asset_gatekeepers.include?(person)
    end
  end

  test 'project_administrators' do
    User.with_current_user(Factory(:admin)) do
      person = Factory(:person_in_multiple_projects)
      proj1 = person.projects.first
      proj2 = person.projects.last
      person.is_project_administrator = true, proj1
      person.save!

      assert proj1.project_administrators.include?(person)
      assert !proj2.project_administrators.include?(person)
    end
  end

  test 'asset_managers' do
    User.with_current_user(Factory(:admin)) do
      person = Factory(:person_in_multiple_projects)
      proj1 = person.projects.first
      proj2 = person.projects.last
      person.is_asset_housekeeper = true, proj1
      person.save!

      assert proj1.asset_housekeepers.include?(person)
      assert !proj2.asset_housekeepers.include?(person)
    end
  end

  test 'pals' do
    User.with_current_user(Factory(:admin)) do
      person = Factory(:person_in_multiple_projects)
      proj1 = person.projects.first
      proj2 = person.projects.last
      person.is_pal = true, proj1
      person.save!

      assert proj1.pals.include?(person)
      assert !proj2.pals.include?(person)
    end
  end

  test 'without programme' do
    p1 = Factory(:project)
    p2 = Factory(:project, programme: Factory(:programme))
    ps = Project.without_programme
    assert_includes ps, p1
    refute_includes ps, p2
  end

  test 'ancestor and dependants' do
    p = Factory(:project)
    p2 = Factory(:project)

    assert_nil p2.lineage_ancestor
    assert_empty p.lineage_descendants

    p.lineage_ancestor = p
    refute p.valid?

    p2.lineage_ancestor = p
    assert p2.valid?
    disable_authorization_checks { p2.save! }
    p2.reload
    p.reload

    assert_equal p, p2.lineage_ancestor
    assert_equal [p2], p.lineage_descendants

    # repeat, but assigning the other way around
    p = Factory(:project)
    p2 = Factory(:project)

    assert_nil p2.lineage_ancestor
    assert_empty p.lineage_descendants

    disable_authorization_checks do
      p2.lineage_descendants << p
      assert p2.valid?
      p2.save!
    end

    p2.reload
    p.reload

    assert_equal [p], p2.lineage_descendants
    assert_equal p2, p.lineage_ancestor

    p3 = Factory(:project)
    disable_authorization_checks do
      p2.lineage_descendants << p3
      p2.save!
    end

    p2.reload
    assert_equal [p, p3], p2.lineage_descendants.sort_by(&:id)
  end

  test 'spawn' do
    p = Factory(:programme, projects: [Factory(:project, avatar: Factory(:avatar))]).projects.first
    wg1 = Factory(:work_group, project: p)
    wg2 = Factory(:work_group, project: p)
    person = Factory(:person, group_memberships: [Factory(:group_membership, work_group: wg1)])
    person2 = Factory(:person, group_memberships: [Factory(:group_membership, work_group: wg1)])
    person3 = Factory(:person, group_memberships: [Factory(:group_membership, work_group: wg2)])
    p.reload

    assert_equal 3, p.people.size
    assert_equal 2, p.work_groups.size
    assert_includes p.people, person
    assert_includes p.people, person2
    assert_includes p.people, person3
    refute_nil p.avatar

    p2 = p.spawn
    assert p2.new_record?

    assert_equal p2.title, p.title
    assert_equal p2.description, p.description
    assert_equal p2.programme, p.programme

    p2.title = 'sdfsdflsdfoosdfsdf' # to allow it to save

    disable_authorization_checks { p2.save! }
    p2.reload
    p.reload

    assert_nil p2.avatar
    refute_equal p, p2
    refute_includes p2.work_groups, wg1
    refute_includes p2.work_groups, wg2

    assert_equal 2, p2.work_groups.size

    assert_equal p.institutions.sort, p2.institutions.sort
    assert_equal p.people.sort, p2.people.sort
    assert_equal 3, p2.people.size

    assert_includes p2.people, person
    assert_includes p2.people, person2
    assert_includes p2.people, person3

    assert_equal p, p2.lineage_ancestor
    assert_equal [p2], p.lineage_descendants

    prog2 = Factory(:programme)
    p2 = p.spawn(title: 'fish project', programme_id: prog2.id, description: 'about doing fishing')
    assert p2.new_record?

    assert_equal 'fish project', p2.title
    assert_equal prog2, p2.programme
    assert_equal 'about doing fishing', p2.description
  end

  test 'spawn consolidates workgroups' do
    p = Factory(:programme, projects: [Factory(:project, avatar: Factory(:avatar))]).projects.first
    wg1 = Factory(:work_group, project: p)
    wg2 = Factory(:work_group, project: p)
    Factory(:group_membership, work_group: wg1, person: Factory(:person))
    Factory(:group_membership, work_group: wg1, person: Factory(:person))
    Factory(:group_membership, work_group: wg1, person: Factory(:person))
    Factory(:group_membership, work_group: wg2, person: Factory(:person))
    Factory(:group_membership, work_group: wg2, person: Factory(:person))
    p.reload
    assert_equal 5, p.people.count
    assert_equal 2, p.work_groups.count
    p2 = nil
    assert_difference('WorkGroup.count', 2) do
      assert_difference('GroupMembership.count', 5) do
        assert_difference('Project.count', 1) do
          assert_no_difference('Person.count') do
            p2 = p.spawn(title: 'sdfsdfsdfsdf')
            disable_authorization_checks { p2.save! }
          end
        end
      end
    end
    p2.reload
    assert_equal 5, p2.people.count
    assert_equal 2, p2.work_groups.count
    refute_equal p.work_groups.sort, p2.work_groups.sort
    assert_equal p.people, p2.people
  end

  test 'can create?' do
    User.current_user = nil
    refute Project.can_create?

    User.current_user = Factory(:person).user
    refute Project.can_create?

    User.current_user = Factory(:project_administrator).user
    refute Project.can_create?

    User.current_user = Factory(:admin).user
    assert Project.can_create?

    person = Factory(:programme_administrator)
    User.current_user = person.user
    programme = person.administered_programmes.first
    assert programme.is_activated?
    assert Project.can_create?

    # only if the programme is activated
    person = Factory(:programme_administrator)
    programme = person.administered_programmes.first
    programme.is_activated = false
    disable_authorization_checks { programme.save! }
    User.current_user = person.user
    refute Project.can_create?
  end

  test 'project programmes' do
    project = Factory(:project)
    assert_empty project.programmes
    assert_nil project.programme

    prog = Factory(:programme)
    project = prog.projects.first
    assert_equal [prog], project.programmes
  end

  test 'mass assigment' do
    # check it is possible to mass assign all the attributes
    programme = Factory(:programme)
    institution = Factory(:institution)
    person = Factory(:person)
    organism = Factory(:organism)
    other_project = Factory(:project)

    attr = {
      title: 'My Project',
      wiki_page: 'http://wikipage.com',
      web_page: 'http://webpage.com',
      organism_ids: [organism.id],
      institution_ids: [institution.id],
      parent_id: [other_project.id],
      description: 'Project description',
      project_administrator_ids: [person.id],
      asset_gatekeeper_ids: [person.id],
      pal_ids: [person.id],
      asset_housekeeper_ids: [person.id]
    }

    project = Project.create(attr)
    disable_authorization_checks { project.save! }
    project.reload

    assert_include project.organisms, organism
    assert_equal 'Project description', project.description
    assert_equal 'http://wikipage.com', project.wiki_page
    assert_equal 'http://webpage.com', project.web_page
    assert_equal 'My Project', project.title

    # people with special roles need setting after the person belongs to the project,
    # otherwise non-members are stripped out when assigned
    person.add_to_project_and_institution(project, Factory(:institution))
    person.save!
    person.reload

    attr = {
      project_administrator_ids: [person.id],
      asset_gatekeeper_ids: [person.id],
      pal_ids: [person.id],
      asset_housekeeper_ids: [person.id]
    }
    project.update_attributes(attr)

    assert_include project.project_administrators, person
    assert_include project.asset_gatekeepers, person
    assert_include project.pals, person
    assert_include project.asset_housekeepers, person
  end

  test 'project role removed when removed from project' do
    project_administrator = Factory(:project_administrator).reload
    project = project_administrator.projects.first

    assert_includes project_administrator.roles, 'project_administrator'
    assert_includes project.project_administrators, project_administrator
    assert project_administrator.is_project_administrator?(project)
    assert project_administrator.user.is_project_administrator?(project)
    assert project_administrator.user.person.is_project_administrator?(project)
    assert project.can_be_administered_by?(project_administrator.user)

    project_administrator.group_memberships.destroy_all
    project_administrator = project_administrator.reload

    assert_not_includes project_administrator.roles, 'project_administrator'
    assert_not_includes project.project_administrators, project_administrator
    assert !project_administrator.is_project_administrator?(project)
    assert !project.can_be_administered_by?(project_administrator.user)
  end

  test 'project role removed when marked as left project' do
    project_administrator = Factory(:project_administrator).reload
    project = project_administrator.projects.first

    assert_includes project_administrator.roles, 'project_administrator'
    assert_includes project.project_administrators, project_administrator
    assert project_administrator.is_project_administrator?(project)
    assert project_administrator.user.is_project_administrator?(project)
    assert project_administrator.user.person.is_project_administrator?(project)
    assert project.can_be_administered_by?(project_administrator.user)

    project_administrator.group_memberships.first.update_attributes(time_left_at: 1.day.ago)
    project_administrator = project_administrator.reload

    assert_not_includes project_administrator.roles, 'project_administrator'
    assert_not_includes project.project_administrators, project_administrator
    assert !project_administrator.is_project_administrator?(project)
    assert !project.can_be_administered_by?(project_administrator.user)
  end
end
