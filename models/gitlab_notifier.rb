class GitlabNotifier < Jenkins::Tasks::Publisher

  display_name 'Gitlab Notifier'

  def initialize(attrs)
    puts "#{self.class}#initialize #{attrs}"
  end

  def prebuild(build, listener)
    puts "#{self.class}#prebuild( #{build} , #{listener} )"
  end

  def perform(build, launcher, listener)
    puts "#{self.class}#perform( #{build} , #{launcher} , #{listener} )"
  end

end
