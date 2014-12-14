require_relative '../services/get_jenkins_projects'

module GitlabWebHook
  class ProcessMergeRequest

    def initialize(get_jenkins_projects = GetJenkinsProjects.new)
      @get_jenkins_projects = get_jenkins_projects
    end

    def with(details)
      messages = []
      if details.merge_status != 'mergeable'
        messages << "Skipping not ready merge request for #{details.repository_name} with #{details.merge_status} status"
      else
        project_name = "#{details.repository_name}-mr-#{details.safe_branch}"
        case details.state
        when 'opened', 'reopened'
          messages << "Create project for #{details.safe_branch} from #{details.repository_name}"
          projects = get_projects_to_process(details)
        when 'closed'
          messages << "Deleting project #{project_name}"
        else
          messages << "Skipping request : merge request status is '#{details.state}'"
        end
      end
      messages
    end

    private

    def get_projects_to_process(details)
      projects = @get_jenkins_projects.matching_uri(details)
    end

  end
end
