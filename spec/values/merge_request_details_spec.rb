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

    context '#classic?' do
      it 'is true' do
        expect(subject.classic?).to eq(false)
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

    context '#repository_url' do
      it 'returns ssh url for repository' do
        expect(subject.repository_url).to eq('git@localhost:peronospora.git')
      end
    end

    context '#repository_name' do
      it 'returns for repository' do
        expect(subject.repository_name).to eq('diaspora')
      end
    end

    context '#repository_homepage' do
      it 'returns for repository' do
        expect(subject.repository_homepage).to eq('http://localhost/peronospora')
      end
    end

    context '#full_branch_reference' do
      it 'returns for repository' do
        expect(subject.full_branch_reference).to eq('ms-viewport')
      end
    end

    context '#delete_branch_commit?' do
      it 'returns for repository' do
        expect(subject.delete_branch_commit?).to eq(false)
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
