require_relative 'abstract_details'
require_relative '../exceptions/bad_request_exception'

require 'net/http'

module GitlabWebHook
  class MergeRequestDetails < AbstractDetails

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
      return "" unless payload['source_project_id']
      payload['source_project_id'].to_s
    end

    def branch
      return "" unless payload['source_branch']
      payload['source_branch']
    end

    def target_project_id
      return "" unless payload['target_project_id']
      payload['target_project_id'].to_s
    end

    def target_branch
      return "" unless payload['target_branch']
      payload['target_branch']
    end

    def state
      return "" unless payload['state']
      payload['state']
    end

    def merge_status
      return "" unless payload['merge_status']
      payload['merge_status']
    end

    def repository_url
      payload["source"] ? git_url(payload["source"]["ssh_url"]) : extended["ssh_url_to_repo"]
    end

    def repository_name
      payload["source"] ? payload["source"]["name"] : extended["name"]
    end

    def repository_homepage
      payload["source"] ? payload["source"]["http_url"] : extended["web_url"]
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
      req.verify_mode = OpenSSL::SSL::VERIFY_NONE

      res = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
        http.request req
      end

      JSON.parse( res.body )
    end

    def git_url ssh_url
      ssh_url.split('/',4).slice(2,2).join(':')
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
