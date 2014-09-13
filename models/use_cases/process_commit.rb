
require 'gitlab_web_hook'

require_relative 'create_project_for_branch'

module GitlabWebHook
  class ProcessCommit
    def initialize(get_jenkins_projects = GetJenkinsProjects.new, create_project_for_branch = CreateProjectForBranch.new)
      @get_jenkins_projects = get_jenkins_projects
      @create_project_for_branch = create_project_for_branch
    end

    def with(details)
      projects = get_projects_to_process(details)

      messages = []
      projects.each do |project|
        messages << BuildNow.new(project).with(details)
      end
      messages
    end

    private

    def get_projects_to_process(details)
      if Settings.automatic_project_creation?
        projects = @get_jenkins_projects.exactly_matching(details)
        projects << @create_project_for_branch.with(details) if projects.empty?
      else
        projects = @get_jenkins_projects.matching(details)
      end
      raise NotFoundException.new('no project references the given repo url and commit branch') if projects.empty?

      projects
    end
  end
end
