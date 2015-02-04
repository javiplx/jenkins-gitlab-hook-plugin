require 'net/http'
require 'json'

module Gitlab
  class Client

    attr_reader :id, :ssh_url, :name

    def initialize(descriptor, repo_name=nil)
      @gitlab_url = descriptor.gitlab_url
      @token = descriptor.token
      self.name = repo_name if repo_name
    end

    def name=(repo_namespace)
      if @name = repo_namespace.split('/').last.split('.')[0]
        @ssh_url = repo_namespace
        @id = repo_id
      end
    end

    def post_status(commit, status, ci_url)
      url = "projects/#{id}/repository/commits/#{commit}/status"
      do_request url, :state => status, :target_url => ci_url
    end

    private

    attr_accessor :gitlab_url, :token

    def merge_requests(project)
      source = project.scm.branches.first.name
      target = project.pre_build_merge.get_options.merge_target
      do_request("projects/#{id}/merge_requests?state=opened").each do |mr|
        return mr['id'] if mr['source_branch'] == source && mr['target_branch'] == target
      end
      raise StandardError.new("No valid match")
    end

    def repo_id
      do_request("projects/search/#{name}").each do |repo|
        return repo['id'] if repo['ssh_url_to_repo'].end_with?(ssh_url)
      end
      raise StandardError.new("No valid match")
    end

    def do_request(url, data=nil)

      uri = URI "#{gitlab_url}/#{url}"

      if data
        req = Net::HTTP::Post.new uri.request_uri
        req.set_form_data data
      else
        req = Net::HTTP::Get.new uri.request_uri
      end

      req['PRIVATE-TOKEN'] = token

      http = Net::HTTP.new uri.host, uri.port
      if uri.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      res = http.request req

      JSON.parse res.body
    end

  end
end
