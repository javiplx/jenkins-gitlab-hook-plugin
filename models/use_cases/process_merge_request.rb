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
          if @get_jenkins_projects.named(project_name).any?
            messages << "Already created project for #{details.safe_branch} on #{details.repository_name}"
          else
            projects = get_project_candidates(details)
            if projects.any?
              messages << "Create project for #{details.safe_branch} from #{details.repository_name}"
            else
              messages << "No project candidate for merging #{details.safe_branch}"
            end
          end
        when 'closed'
          if @get_jenkins_projects.named(project_name).any?
            messages << "Deleting project #{project_name}"
          else
            messages << "No project exists for #{project_name}"
          end
        else
          messages << "Skipping request : merge request status is '#{details.state}'"
        end
      end
      messages
    end

    private

    def get_project_candidates(details)
      projects = @get_jenkins_projects.matching_uri(details)
    end

  end
end
