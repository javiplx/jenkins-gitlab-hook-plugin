require 'spec_helper'

require 'models/root_action_descriptor'

module GitlabWebHook
  describe ProcessMergeRequest do

    let (:payload) { JSON.parse(File.read('spec/fixtures/new_merge_request_payload.json')) }
    let (:details) { MergeRequestDetails.new(payload) }

    context 'with cross-repo merge request' do
      let(:details) { double(MergeRequestDetails, source_project_id: '14', target_project_id: '15') }
      it 'raise exception' do
        expect { subject.with(details) }.to raise_exception(BadRequestException)
      end
    end

    context 'when merge request is unchecked' do
      it 'skips processing' do
        messages = subject.with(details)
        expect(messages[0]).to match('Skipping not ready merge request')
      end
    end

    context 'when merge request is mergeable' do

      before :each do
        expect(details).to receive(:merge_status).and_return( 'mergeable' )
      end

      context 'and status is opened' do
        it 'and project already exists' do
        end
        it 'and project does not exists' do
        end
      end

      context 'and status is closed' do
        it 'and project already exists' do
        end
        it 'and project does not exists' do
        end
      end

      context 'and status is reopened' do
        it 'and project already exists' do
        end
        it 'and project does not exists' do
        end
      end

    end

  end
end
