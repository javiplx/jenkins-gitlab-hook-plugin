require 'net/http'
require 'json'

module Gitlab
  class Client

    attr_accessor :gitlab_url, :token

    def initialize(url, token)
      @gitlab_url = url
      @token = token

    end

    def get_id(repo_name)
      url = "#{gitlab_url}/projects/search/#{repo_name}?private_token=#{token}"
      res = do_request url
      raise StandardError.new("No valid match") unless res.length == 1
      res.first['id']
    end

    def set_status(commit, status, url)
      url = "#{gitlab_url}/projects/1/repository/commits/#{commit}/status?private_token=#{token}"
      do_post url, :state => status, :target_url => url
    end

    private

    def do_request(url)

      uri = URI url
      req = Net::HTTP::Get.new uri.request_uri

      http = Net::HTTP.new uri.host, uri.port
      res = http.request req

      JSON.parse res.body
    end

    def do_post(url, data)

      uri = URI url
      req = Net::HTTP::Post.new uri.request_uri
      req.set_form_data data

      http = Net::HTTP.new uri.host, uri.port
      res = http.request req

      JSON.parse res.body
    end

  end
end
