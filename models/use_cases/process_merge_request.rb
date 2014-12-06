require_relative '../exceptions/bad_request_exception'

module GitlabWebHook
  class ProcessMergeRequest
    def with(details)
      raise BadRequestException.new("Handling of merge requests not yet implemented")
    end
  end
end
