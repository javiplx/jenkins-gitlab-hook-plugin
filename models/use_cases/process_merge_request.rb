
module GitlabWebHook
  class ProcessMergeRequest
    def with(details)
      messages = []
      if details.merge_status != 'mergeable'
        messages << "Skipping merge request for #{details.repository_name} with #{details.merge_status} status"
      else
        case details.state
        when 'opened', 'reopened'
          messages << "Skipping not ready merge request for #{details.repository_name}"
        when 'closed'
          messages << "Skipping merge request close message"
        else
          messages << "Skipping request : merge request status is '#{details.state}'"
        end
      end
      messages
    end
  end
end
