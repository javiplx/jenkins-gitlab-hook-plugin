require 'spec_helper'

module GitlabWebHook
  describe MergeRequestDetails do

    let (:payload) { JSON.parse(File.read('spec/fixtures/merge_request_payload.json')) }
    let (:subject) { MergeRequestDetails.new(payload) }

    context 'when initializing' do
      it 'requires payload data' do
        expect { MergeRequestDetails.new(nil) }.to raise_exception(ArgumentError)
      end
    end

    context '#extended?' do
      it 'is true' do
        expect(subject.extended?).to eq(true)
      end
    end

    context '#kind' do
      it 'is merge request' do
        expect(subject.kind).to eq('merge_request')
      end
    end

    context '#project_id' do
      it 'parsed from payload' do
        expect(subject.project_id).to eq('14')
      end

      it 'returns empty when no source project found' do
        payload.delete('project_id')
        expect(subject.project_id).to eq('')
      end
    end

    context '#url' do
      it 'returns ssh url for repository' do
        expect(subject.project_id).to eq('git@example.com:diaspora.git')
      end
    end

    context '#source_branch' do
      it 'parsed from payload' do
        expect(subject.source_branch).to eq('ms-viewport')
      end

      it 'returns empty when no source branch found' do
        payload.delete('source_branch')
        expect(subject.source_branch).to eq('')
      end
    end

    context '#target_project_id' do
      it 'parsed from payload' do
        expect(subject.target_project_id).to eq('14')
      end

      it 'returns empty when no target project found' do
        payload.delete('target_project_id')
        expect(subject.target_project_id).to eq('')
      end
    end

    context '#target_branch' do
      it 'parsed from payload' do
        expect(subject.target_branch).to eq('master')
      end

      it 'returns empty when no target branch found' do
        payload.delete('target_branch')
        expect(subject.target_branch).to eq('')
      end
    end

    context '#state' do
      it 'parsed from payload' do
        expect(subject.state).to eq('opened')
      end

      it 'returns empty when no state data found' do
        payload.delete('state')
        expect(subject.state).to eq('')
      end
    end

    context '#merge_status' do
      it 'parsed from payload' do
        expect(subject.merge_status).to eq('unchecked')
      end

      it 'returns empty when no merge status data found' do
        payload.delete('merge_status')
        expect(subject.merge_status).to eq('')
      end
    end

  end
end
