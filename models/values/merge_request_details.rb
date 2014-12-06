require_relative 'request_details'
require_relative '../exceptions/bad_request_exception'

module GitlabWebHook
  class MergeRequestDetails < RequestDetails

    def initialize(payload)
      raise(ArgumentError.new("request payload is required")) unless payload
      @kind = payload['object_kind']
      @payload = payload['object_attributes']
      throw_cross_repo_exception unless project_id == target_project_id
    end

    def valid?
      kind == 'merge_request'
    end

    def project_id
      payload['source_project_id'].to_s
    end

    def source_branch
     payload['source_branch']
    end

    def target_project_id
      payload['target_project_id'].to_s
    end

    def target_branch
     payload['target_branch']
    end

    def state
     payload['state']
    end

    def merge_status
     payload['merge_status']
    end

    private

    def throw_cross_repo_exception
      message = "Cross-repo merge requests not supported"
      raise BadRequestException.new(message)
    end

    def get_payload
      @payload
    end

  end
end
