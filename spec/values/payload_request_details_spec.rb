require 'spec_helper'

module GitlabWebHook
  describe PayloadRequestDetails do
    include_context 'details'
    let (:subject) { PayloadRequestDetails.new(payload) }

    context 'when initializing' do
      it 'requires payload data' do
        expect { PayloadRequestDetails.new(nil) }.to raise_exception(ArgumentError)
      end
    end

    it '#kind is web hook' do
      expect(subject.kind).to eq('push')
    end

    context 'with repository url' do
      it 'extracts from payload' do
        expect(subject.repository_url).to eq('git@example.com:mike/diaspora.git')
      end

      it 'returns empty when no repository details found' do
        payload.delete('project')
        payload.delete('repository')
        expect(subject.repository_url).to eq('')
      end
    end

    context 'with repository name' do
      it 'extracts from payload' do
        expect(subject.repository_name).to eq('Diaspora')
      end

      it 'returns empty when no repository details found' do
        payload.delete('project')
        payload.delete('repository')
        expect(subject.repository_name).to eq('')
      end
    end

    context 'with repository homepage' do
      it 'extracts from payload' do
        expect(subject.repository_homepage).to eq('http://example.com/mike/diaspora')
      end

      it 'returns empty when no repository details found' do
        payload.delete('project')
        payload.delete('repository')
        expect(subject.repository_homepage).to eq('')
      end
    end

    context 'with full branch reference' do
      it 'extracts from payload' do
        expect(subject.full_branch_reference).to eq('refs/heads/master')
      end

      it 'returns empty when no branch reference data found' do
        payload.delete('ref')
        expect(subject.full_branch_reference).to eq('')
      end
    end

    context 'with delete branch commit' do
      it 'defaults to false' do
        expect(subject.delete_branch_commit?).not_to be
      end

      it 'detects delete branch commit' do
        payload['after'] = '00000000000000000'
        expect(subject.delete_branch_commit?).to be
      end
    end

    context 'with commits' do
      it 'extracts from payload' do
        expect(subject.commits.size).to eq(2)

        expect(subject.commits[0].url).to eq('http://example.com/mike/diaspora/commit/b6568db1bc1dcd7f8b4d5a946b0b91f9dacd7327')
        expect(subject.commits[0].message).to eq('Update Catalan translation to e38cb41.')

        expect(subject.commits[1].url).to eq('http://example.com/mike/diaspora/commit/da1560886d4f094c3e6c9ef40349f7d38b5d27d7')
        expect(subject.commits[1].message).to eq('fixed readme')
      end

      it 'memoizes the result' do
        expect(payload).to receive(:[]).with('commits').once.and_return(payload['commits'])
        expect(payload).to receive(:[]).with('object_kind').twice.and_return('webhook')
        10.times { subject.commits }
      end

      it 'returns empty array when no commits details found' do
        payload.delete('commits')
        expect(subject.commits).to eq([])
      end
    end

    context 'with payload' do
      it 'returns it' do
        expect(subject.payload).to eq(payload)
      end
    end
  end
end
