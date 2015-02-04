require 'gitlab'

class GitlabNotifier < Jenkins::Tasks::Publisher

  display_name 'Gitlab Notifier'

  transient :descriptor, :client

  attr_reader :client

  def initialize(attrs)
    create_client
  end

  def read_completed
    create_client
  end

  def prebuild(build, listener)
    client.name = repo_namespace(build)
    env = build.native.environment listener
    client.post_status( env['GIT_COMMIT'] , 'running' , env['BUILD_URL'] )
  end

  def perform(build, launcher, listener)
    env = build.native.environment listener
    parents = StringIO.new
    launcher.execute('git', 'log', '-1', '--oneline' ,'--format=%P', {:out => parents, :chdir => build.workspace} )
    parents_a = parents.string.split
    if parents_a.length == 1
      client.post_status( env['GIT_COMMIT'] , build.native.result , env['BUILD_URL'] )
    else
      client.post_status( parents_a.last , build.native.result , env['BUILD_URL'] )
    end
  end

  class GitlabNotifierDescriptor < Jenkins::Model::DefaultDescriptor

    java_import Java.hudson.BulkChange
    java_import Java.hudson.model.listeners.SaveableListener

    attr_reader :gitlab_url, :token

    def initialize(describable, object, describable_type)
      super
      load
    end

    def load
      return unless configFile.file.exists()
      xmlfile = File.new(configFile.file.canonicalPath)
      xmldoc = REXML::Document.new(xmlfile)
      if xmldoc.root
        @gitlab_url = xmldoc.root.elements['gitlab_url'].text
        @token = xmldoc.root.elements['token'].text
      end
    end

    def configure(req, form)
      parse(form)
      save
    end

    def save
      return if BulkChange.contains(self)

      doc = REXML::Document.new
      doc.add_element( 'hudson.model.Descriptor' , { "plugin" => "gitlab-notifier" } )

      doc.root.add_element( 'gitlab_url' ).add_text( gitlab_url )
      doc.root.add_element( 'token' ).add_text( token )

      f = File.open(configFile.file.canonicalPath, 'wb')
      f.puts("<?xml version='#{doc.version}' encoding='#{doc.encoding}'?>")

      formatter = REXML::Formatters::Pretty.new
      formatter.compact = true
      formatter.write doc, f

      f.close

      SaveableListener.fireOnChange(self, configFile)
      f.closed?
    end

    private

    def parse(form)
      @gitlab_url = form["gitlab_url"]
      @token = form['token']
    end

  end

  describe_as Java.hudson.tasks.Publisher, :with => GitlabNotifierDescriptor

  private

  def create_client
    plugin = Java.jenkins.model.Jenkins.instance.getPlugin 'gitlab-hook'
    @descriptor = plugin.native_ruby_plugin.descriptors[GitlabNotifier]
    @client = Gitlab::Client.new @descriptor
  end

  def repo_namespace(build)
    project_scm = build.native.project.scm
    repo_url = project_scm.repositories.first.getURIs.first.to_s
    repo_url.split(':')[1]
  end

end
