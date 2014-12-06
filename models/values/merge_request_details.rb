require_relative 'request_details'
require_relative '../exceptions/bad_request_exception'

require 'net/http'

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

    def repository_url
      extended["ssh_url_to_repo"]
    end

    def repository_name
      extended["name"]
    end

    def repository_homepage
      extended["web_url"]
    end

    private

    def extended
      @extended ||= get_project_details
    end

    def get_project_details

      gitlab_url = 'http://localhost'
      token = '********'

      uri = URI "#{gitlab_url}/api/v3/projects/#{project_id}?private_token=#{token}"

      req = Net::HTTP::Get.new uri.request_uri

      res = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http.request req
      end

      JSON.parse( res.body )
    end

    def throw_cross_repo_exception
      message = "Cross-repo merge requests not supported"
      raise BadRequestException.new(message)
    end

    def get_payload
      @payload
    end

  end
end
