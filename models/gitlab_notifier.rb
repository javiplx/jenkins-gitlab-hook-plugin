require 'gitlab'

class GitlabNotifier < Jenkins::Tasks::Publisher

  display_name 'Gitlab Notifier'

  transient :descriptor

  def initialize(attrs)
    puts "#{self.class}#initialize #{attrs}"
    plugin = Java.jenkins.model.Jenkins.instance.getPlugin 'gitlab-hook'
    @descriptor = plugin.native_ruby_plugin.descriptors[GitlabNotifier.class]
  end

  def prebuild(build, listener)
    puts "#{self.class}#prebuild( #{build} , #{listener} )"
    env_vars = build.native.environment listener
    @commit = env_vars['GIT_COMMIT']
    @url = env_vars['BUILD_URL']
  end

  def perform(build, launcher, listener)
    puts "#{self.class}#perform( #{build} , #{launcher} , #{listener} )"
    status = build.native.result
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

  def client
    @client ||= Gitlab::Client.new @descriptor.gitlab_url, @descriptor.token
  end

end
