require 'gitlab_web_hook/values/flat_keys_hash'

module GitlabWebHook
  class PayloadRequestDetails
    def initialize(payload)
      @payload = payload || raise(ArgumentError.new("request payload is required"))
    end

    def valid?
      repository_url.to_s.strip.empty? ? false : true
    end

    def repository_uri
      RepositoryUri.new(repository_url)
    end

    def repository_url
      return "" unless payload["repository"]
      return "" unless payload["repository"]["url"]
      payload["repository"]["url"].strip
    end

    def repository_name
      return "" unless payload["repository"]
      return "" unless payload["repository"]["name"]
      payload["repository"]["name"].strip
    end

    def repository_homepage
      return "" unless payload["repository"]
      return "" unless payload["repository"]["homepage"]
      payload["repository"]["homepage"].strip
    end

    def full_branch_reference
      payload["ref"].to_s.strip
    end

    def branch
      ref = full_branch_reference
      return "" unless ref

      refs = ref.split("/")
      refs.reject { |ref| ref =~ /\A(ref|head)s?\z/ }.join("/")
    end

    def safe_branch
      branch.gsub("/", "_")
    end

    def delete_branch_commit?
      after = payload["after"]
      after ? (after.strip.squeeze == "0") : false
    end

    def commits
      commits = get_commits || []
      raise ArgumentError.new("payload must be an array") unless commits.is_a?(Array)
      commits
    end

    def commits_count
      commits ? commits.size : 0
    end

    def payload
      payload = get_payload || {}
      raise ArgumentError.new("payload must be a hash") unless payload.is_a?(Hash)
      payload
    end

    def flat_payload
      @flat_payload ||= payload.extend(FlatKeysHash).to_flat_keys.tap do |flattened|
        [
          :repository_url,
          :repository_name,
          :repository_homepage,
          :full_branch_reference,
          :branch
        ].each { |detail| flattened[detail.to_s] = self.send(detail) }
      end
    end

    private

    def get_commits
      @commits ||= payload["commits"].to_a.map do |commit|
        Commit.new(commit["url"], commit["message"])
      end
    end

    def get_payload
      @payload
    end
  end
end
