require 'gitlab'

require 'jenkins/model/global_descriptor'

class GitlabNotifier < Jenkins::Tasks::Publisher

  display_name 'Gitlab commit status publisher'

  transient :descriptor, :client

  attr_reader :descriptor, :client

  def initialize(attrs)
    create_client
  end

  def read_completed
    create_client
  end

  def prebuild(build, listener)
    return unless descriptor.commit_status?
    project = GitlabWebHook::Project.new build.native.project
    client.name = repo_namespace(project)
    env = build.native.environment listener
    sha = post_commit env['GIT_COMMIT'] , build, listener
    client.post_status( sha , 'running' , env['BUILD_URL'] )
  end

  def perform(build, launcher, listener)
    project = GitlabWebHook::Project.new build.native.project
    mr_id = client.merge_request(project)
    return if mr_id == -1 && descriptor.mr_status_only?
    env = build.native.environment listener
    sha = post_commit env['GIT_COMMIT'] , build, listener
    client.post_status( sha , build.native.result , env['BUILD_URL'] , descriptor.commit_status? ? nil : mr_id )
  end

  class GitlabNotifierDescriptor < Jenkins::Model::GlobalDescriptor

    attr_reader :gitlab_url, :token

    def commit_status?
      @commit_status == 'true'
    end

    def mr_status_only?
      @mr_status_only == 'true'
    end

    private

    def load_xml(xmlroot)
      @gitlab_url = xmlroot.elements['gitlab_url'].text
      @token = xmlroot.elements['token'].text
      @commit_status = xmlroot.elements['commit_status'].nil? ? 'false' : xmlroot.elements['commit_status'].text
      @mr_status_only = xmlroot.elements['mr_status_only'].nil? ? 'true' : xmlroot.elements['mr_status_only'].text
    end

    def store_xml(xmlroot)
      xmlroot.add_element( 'gitlab_url' ).add_text( gitlab_url )
      xmlroot.add_element( 'token' ).add_text( token )
      xmlroot.add_element( 'commit_status' ).add_text( @commit_status )
      xmlroot.add_element( 'mr_status_only' ).add_text( @mr_status_only )
    end

    def parse(form)
      @gitlab_url = form["gitlab_url"]
      @token = form['token']
      @commit_status = form['commit_status'] ? 'true' : 'false'
      @mr_status_only = form['mr_status_only'] ? 'true' : 'false'
    end

  end

  describe_as Java.hudson.tasks.Publisher, :with => GitlabNotifierDescriptor

  private

  def clone_dir( build )
    if local_branch = GitlabWebHook::Project.new(build.native.project).local_clone
      build.workspace + local_branch
    else
      build.workspace
    end
  end

  def post_commit(current, build, listener)
    gitlog = StringIO.new
    launcher = build.workspace.create_launcher(listener)
    if launcher.execute('git', 'log', '-1', '--oneline' ,'--format=%P', {:out => gitlog, :chdir => clone_dir(build)} ) == 0
      parents = gitlog.string.split
    else
      listener.warning( "git-log failed : '#{parents.join(' ')}'" )
    end
    parents[0] = current
    parents.last
  end

  def create_client
    @descriptor = Jenkins::Plugin.instance.descriptors[GitlabNotifier]
    @client = Gitlab::Client.new @descriptor
  end

  def repo_namespace(project)
    repo_url = project.scm.repositories.first.getURIs.first.to_s
    repo_url.split(':')[1]
  end

end
