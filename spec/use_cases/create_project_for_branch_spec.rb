require 'spec_helper'

require 'models/root_action_descriptor'

module GitlabWebHook

  module PluginManager
  end
  module PluginWrapper
  end

  describe CreateProjectForBranch do
    let(:details) { double(RequestDetails, repository_name: 'discourse', safe_branch: 'features_meta', branch: 'features/meta', repository_homepage: 'http://gitlab.com/group/discourse') }
    let(:jenkins_project) { double(AbstractProject) }
    let(:master) { double(Project, name: 'discourse', jenkins_project: jenkins_project) }
    let(:get_jenkins_projects) { double(GetJenkinsProjects, master: master, named: []) }
    let(:subject) { CreateProjectForBranch.new(get_jenkins_projects) }
    let(:jenkins_instance) { double(Java.jenkins.model.Jenkins) }

    before(:each) do
      allow(Java.jenkins.model.Jenkins).to receive(:instance) { jenkins_instance }
      allow(jenkins_instance).to receive(:descriptor) { GitlabWebHookRootActionDescriptor.new }
    end

    context 'when not able to find a master project to copy from' do
      it 'raises appropriate exception' do
        allow(get_jenkins_projects).to receive(:master).with(details) { nil }
        expect { subject.with(details) }.to raise_exception(NotFoundException)
      end
    end

    context 'when branch project already exists' do
      it 'raises appropriate exception' do
        allow(get_jenkins_projects).to receive(:named) { [double] }
        expect { subject.with(details) }.to raise_exception(ConfigurationException)
      end
    end

    context 'when naming the branch project' do

      it 'uses master project name with appropriate settings' do
        expect(subject.send(:get_new_project_name, master, details)).to match(master.name)
      end

      it 'uses repository name with appropriate settings' do
        expect(subject.send(:get_new_project_name, master, details)).to match(details.repository_name)
      end
    end

    context 'when creating the branch project' do
      let(:remote_config) { double(getUrl: 'http://localhost/diaspora', getName: 'Diaspora') }
      let(:source_scm) { double(getScmName: 'git', getUserRemoteConfigs: [remote_config]).as_null_object }
      let(:jenkins_instance) { double(Java.jenkins.model.Jenkins) }
      let(:new_jenkins_project) { double(AbstractProject).as_null_object }

      before(:each) do
        allow(master).to receive(:scm) { source_scm }
        allow(Java.jenkins.model.Jenkins).to receive(:instance) { jenkins_instance }
      end

      it 'fails if remote url could not be determined' do
        allow(remote_config).to receive(:getUrl) { nil }
        expect { subject.with(details) }.to raise_exception(ConfigurationException)
      end

      context 'returns a new project' do

        let(:plugin_manager) { double(PluginManager) }
        let(:gitplugin) { double(PluginWrapper) }

        before(:each) do
          expect(jenkins_instance).to receive(:copy).with(jenkins_project, anything).and_return(new_jenkins_project)
          expect(jenkins_instance).to receive(:getPluginManager).and_return(plugin_manager)
          expect(plugin_manager).to receive(:getPlugin).with('git').and_return(gitplugin)
          expect(GitSCM).to receive('new')
        end

        it 'with git plugin < 2.0' do
          expect(gitplugin).to receive(:isOlderThan) { true }
          branch_project = subject.with(details)
          expect(branch_project).to be_kind_of(Project)
          expect(branch_project.jenkins_project).to eq(new_jenkins_project)
        end

        it 'with git plugin >= 2.0' do
          expect(gitplugin).to receive(:isOlderThan) { false }
          allow(UserRemoteConfig).to receive('new').with(anything, anything, anything, anything)
          allow(remote_config).to receive(:getCredentialsId) { 'sha_id' }
          branch_project = subject.with(details)
          expect(branch_project).to be_kind_of(Project)
          expect(branch_project.jenkins_project).to eq(new_jenkins_project)
        end

      end
    end
  end
end
