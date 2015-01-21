require 'spec_helper'

module GitlabWebHook
  describe ProcessCommit do
    let(:details) { double(RequestDetails, repository_uri: 'git@gitlab.com/group/discourse', branch: 'master', repository_name: 'discourse', repository_group: 'group') }
    let(:action) { double(Proc) }
    let(:project) { double(Project) }
    let(:get_jenkins_projects) { double(GetJenkinsProjects) }
    let(:create_project_for_branch) { double(CreateProjectForBranch) }
    let(:subject) { ProcessCommit.new(get_jenkins_projects, create_project_for_branch) }
    let(:jenkins_instance) { double(Java.jenkins.model.Jenkins) }

    context 'with related projects' do
      before(:each) { allow(subject).to receive(:get_projects_to_process) { [project, project] } }
      it 'calls action with found project and related details' do
        expect(action).to receive(:call).with(project, details).twice
        subject.with(details, action)
      end

      it 'returns messages collected by calls to action' do
        expect(action).to receive(:call).with(project, details).twice.and_return('executed')
        expect(subject.with(details, action)).to eq(%w(executed executed))
      end
    end

    context 'when a project matches payload uri' do
      let(:settings) { double(GitlabWebHookRootActionDescriptor) }

      before(:each) do
        allow(Java.jenkins.model.Jenkins).to receive(:instance) { jenkins_instance }
        allow(jenkins_instance).to receive(:descriptor) { settings }
        allow(settings).to receive(:automatic_project_creation?) { false }
      end

      context 'and automatic project creation is offline' do
        before(:each) { allow(settings).to receive(:automatic_project_creation?) { false } }

        it 'searches matching projects' do
          allow(project).to receive(:matches?) { true }
          expect(get_jenkins_projects).to receive(:matching_uri).with(details).and_return([project])
          expect(create_project_for_branch).not_to receive(:with)
          expect(action).to receive(:call)
          subject.with(details, action)
        end

        it 'raises exception when no matching projects found' do
          expect(get_jenkins_projects).to receive(:matching_uri).with(details).and_return([])
          expect(settings).to receive(:templated_jobs).and_return( {} )
          expect(settings).to receive(:templated_groups).and_return( {} )
          expect(settings).to receive(:template_fallback).and_return( nil )
          expect(create_project_for_branch).not_to receive(:with)
          expect(action).not_to receive(:call)
          expect { subject.with(details, action) }.to raise_exception(NotFoundException)
        end
      end

      context 'and automatic project creation is online' do
        before(:each) { expect(settings).to receive(:automatic_project_creation?) { true } }

        it 'searches exactly matching projects' do
          expect(get_jenkins_projects).to receive(:matching_uri).with(details).and_return([project])
          allow(project).to receive(:matches?) { true }
          expect(create_project_for_branch).not_to receive(:with)
          expect(action).to receive(:call)
          subject.with(details, action)
        end

        it 'creates a new project when no matching projects found' do
          expect(get_jenkins_projects).to receive(:matching_uri).with(details).and_return([project])
          allow(project).to receive(:matches?) { false }
          expect(create_project_for_branch).to receive(:with).with(details).and_return(project)
          expect(action).to receive(:call).with(project, details).once
          subject.with(details, action)
        end
      end
    end

    context 'when no project matches payload uri' do
      let(:settings) { double(GitlabWebHookRootActionDescriptor) }
      #let(:templated_jobs) { {} }
      let(:templated_jobs) { { 'matchstr' => 'job-template'} }
      #let(:templated_groups) { {} }
      let(:templated_groups) { { 'matchstr' => 'group-template'} }

      before(:each) do
        expect(get_jenkins_projects).to receive(:matching_uri).with(details).and_return([])
        allow(Java.jenkins.model.Jenkins).to receive(:instance) { jenkins_instance }
        allow(jenkins_instance).to receive(:descriptor) { settings }
        allow(settings).to receive(:templated_jobs).and_return( templated_jobs )
        allow(settings).to receive(:templated_groups).and_return( templated_groups )
        #allow(settings).to receive(:template_fallback).and_return( nil )
        allow(settings).to receive(:template_fallback).and_return( 'fallback-template' )
      end

      context 'and a template matches repository name' do
        let(:templated_jobs) { { 'disc' => 'reponame-template'} }

        it 'returns the jobname template' do
          expect(settings).not_to receive(:templated_groups)
          expect(settings).not_to receive(:template_fallback)
          expect(create_project_for_branch).to receive(:from_template).with('reponame-template', details).and_return(project)
          expect(action).to receive(:call)
          subject.with(details, action)
        end
      end

      context 'and repo namespace matches some template' do
        let(:templated_groups) { { 'group' => 'repogroup-template' } }

        it 'returns the groupname template' do
          expect(settings).not_to receive(:template_fallback)
          expect(create_project_for_branch).to receive(:from_template).with('repogroup-template', details).and_return(project)
          expect(action).to receive(:call)
          subject.with(details, action)
        end
      end

      context 'and fallback template exists' do
        it 'returns the groupname template' do
          expect(settings).to receive(:template_fallback)
          expect(create_project_for_branch).to receive(:from_template).with('fallback-template', details).and_return(project)
          expect(action).to receive(:call)
          subject.with(details, action)
        end
      end
    end
  end
end
