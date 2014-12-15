require 'spec_helper'

require 'models/root_action_descriptor'

module GitlabWebHook
  describe ProcessMergeRequest do

    let (:payload) { JSON.parse(File.read('spec/fixtures/new_merge_request_payload.json')) }
    let (:details) { MergeRequestDetails.new(payload) }
    let (:get_jenkins_projects) { double(named: []) }
    let (:create_project_for_branch) { double(for_merge: []) }

    before :each do
      expect(GetJenkinsProjects).to receive(:new).and_return( get_jenkins_projects )
      expect(CreateProjectForBranch).to receive(:new).and_return( create_project_for_branch )
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
          expect(get_jenkins_projects).to receive(:named).and_return([double()])
          expect(create_project_for_branch).not_to receive(:for_merge)
          messages = subject.with(details)
          expect(messages[0]).to match('Already created project for')
        end
        context 'and project does not exists' do
          it 'and no destination project exists' do
            messages = subject.with(details)
            expect(messages[0]).to match('No project candidate for')
          end
          it 'and target branch candidate exists' do
            expect(create_project_for_branch).to receive(:for_merge).and_return([double(ignore_notify_commit?: true, to_s: 'project')])
            messages = subject.with(details)
            expect(messages[0]).to match('Created project for')
          end
        end
      end

      context 'and status is closed' do
        before :each do
          expect(details).to receive(:state).and_return( 'closed' )
          expect(create_project_for_branch).not_to receive(:for_merge)
        end
        it 'and project already exists' do
          expect(get_jenkins_projects).to receive(:named).and_return([double()])
          messages = subject.with(details)
          expect(messages[0]).to match('Deleting project')
        end
        it 'and project does not exists' do
          messages = subject.with(details)
          expect(messages[0]).to match('No project exists for')
        end
      end

      context 'and status is reopened' do
        before :each do
          expect(details).to receive(:state).and_return( 'reopened' )
        end
        it 'and project already exists' do
          expect(get_jenkins_projects).to receive(:named).and_return([double()])
          expect(create_project_for_branch).not_to receive(:for_merge)
          messages = subject.with(details)
          expect(messages[0]).to match('Already created project for')
        end
        context 'and project does not exists' do
          it 'and no destination project exists' do
            messages = subject.with(details)
            expect(messages[0]).to match('No project candidate for')
          end
          it 'and target branch candidate exists' do
            expect(create_project_for_branch).to receive(:for_merge).and_return([double(ignore_notify_commit?: true, to_s: 'project')])
            messages = subject.with(details)
            expect(messages[0]).to match('Created project for')
          end
        end
      end

    end

  end
end
