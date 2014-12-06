require_relative '../services/flat_keys_hash'

module GitlabWebHook
  class RequestDetails

    attr_accessor :kind

    def valid?
      classic?
    end

    def repository_uri
      RepositoryUri.new(repository_url)
    end

    def repository_url
      raise NameError.new("should be implemented in concrete implementation")
    end

    def repository_name
      raise NameError.new("should be implemented in concrete implementation")
    end

    def repository_homepage
      raise NameError.new("should be implemented in concrete implementation")
    end

    def full_branch_reference
      raise NameError.new("should be implemented in concrete implementation")
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
      raise NameError.new("should be implemented in concrete implementation")
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

    def classic?
      ['webhook', 'parameters'].include?(kind) && !repository_url.to_s.strip.empty?
    end

    private

    def get_commits
    end

    def get_payload
    end
  end
end
