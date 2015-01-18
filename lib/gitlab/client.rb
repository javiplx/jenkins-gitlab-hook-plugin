require 'net/http'
require 'json'

module Gitlab
  class Client

    def initialize(url, token)
      @gitlab_url = url
      @token = token

    end

    def get_id(repo_name)
      url = "projects/search/#{repo_name}"
      res = do_request url
      raise StandardError.new("No valid match") unless res.length == 1
      res.first['id']
    end

    def set_status(commit, status, ci_url)
      url = "projects/1/repository/commits/#{commit}/status"
      do_request url, :state => status, :target_url => ci_url
    end

    private

    attr_accessor :gitlab_url, :token

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
