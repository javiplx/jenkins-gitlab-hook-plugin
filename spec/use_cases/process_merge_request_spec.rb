require 'spec_helper'

require 'models/root_action_descriptor'

module GitlabWebHook
  describe ProcessMergeRequest do

    let (:payload) { JSON.parse(File.read('spec/fixtures/new_merge_request_payload.json')) }
    let (:details) { MergeRequestDetails.new(payload) }

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
          expect(subject).not_to receive(:get_projects_to_process)
          messages = subject.with(details)
          expect(messages[0]).to match('Already created project for')
        end
        it 'and project does not exists' do
          expect(subject).to receive(:get_projects_to_process)
          messages = subject.with(details)
          expect(messages[0]).to match('Create project for')
        end
      end

      context 'and status is closed' do
        before :each do
          expect(details).to receive(:state).and_return( 'closed' )
          expect(subject).not_to receive(:get_projects_to_process)
        end
        it 'and project already exists' do
          messages = subject.with(details)
          expect(messages[0]).to match('Deleting project')
        end
        it 'and project does not exists' do
          messages = subject.with(details)
          expect(messages[0]).to match('No project exist for')
        end
      end

      context 'and status is reopened' do
        before :each do
          expect(details).to receive(:state).and_return( 'reopened' )
        end
        it 'and project already exists' do
          expect(subject).not_to receive(:get_projects_to_process)
          messages = subject.with(details)
          expect(messages[0]).to match('Already created project for')
        end
        it 'and project does not exists' do
          expect(subject).to receive(:get_projects_to_process)
          messages = subject.with(details)
          expect(messages[0]).to match('Create project for')
        end
      end

    end

  end
end
