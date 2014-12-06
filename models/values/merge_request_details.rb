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
      @kind == 'merge_request'
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
