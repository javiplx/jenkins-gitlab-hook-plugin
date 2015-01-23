require 'net/http'
require 'json'

module Gitlab
  class Client

    attr_reader :id, :name

    def initialize(descriptor, repo_name=nil)
      @gitlab_url = descriptor.gitlab_url
      @token = descriptor.token
      self.name = repo_name if repo_name
    end

    def name=(repo_name)
      if @name = repo_name
        @id = repo_id
      end
    end

    def set_status(commit, status, ci_url)
      url = "projects/#{id}/repository/commits/#{commit}/status"
      do_request url, :state => status, :target_url => ci_url
    end

    private

    attr_accessor :gitlab_url, :token

    def repo_id
      res = do_request "projects/search/#{name}"
      raise StandardError.new("No valid match") unless res.length == 1
      res.first['id']
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
      res = http.request req

      JSON.parse res.body
    end

  end
end
