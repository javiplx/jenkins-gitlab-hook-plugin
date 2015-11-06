require 'jenkins/plugin/specification'
require 'jenkins/plugin/tools/server'

require 'tmpdir'
require 'open-uri'
require 'fileutils'

class Jenkins::Server

  attr_reader :warname, :workdir
  attr_reader :job, :std, :log

  REQUIRED_CORE = '1.532.3'

  def initialize

    download_war( ENV['JENKINS_VERSION'] || REQUIRED_CORE )
    @workdir = Dir.mktmpdir 'work'

    spec = Jenkins::Plugin::Specification.load('jenkins-gitlab-hook.pluginspec')
    server = Jenkins::Plugin::Tools::Server.new(spec, workdir, warname, '8080')

    # Dependencies for git 2.0
    transitive_dependency 'scm-api', '0.1', workdir
    transitive_dependency 'git-client', '1.4.4', workdir
    transitive_dependency 'ssh-agent', '1.3', workdir

    FileUtils.cp_r Dir.glob('work/*'), workdir

    @std, out = IO.pipe
    @log, err = IO.pipe
    @job = fork do
      $stdout.reopen out
      $stderr.reopen err
      server.run!
    end
    Process.detach job

    begin
      line = log.readline
      puts " -> #{line}"
    end until line.include?('Jenkins is fully up and running')


  end

  def kill
    Process.kill 'TERM', job
    dump log, ' -> '
    dump std, ' :: '
    Process.waitpid job, Process::WNOHANG
  rescue Errno::ECHILD => e
  ensure
    Dir["#{workdir}/jobs/*/builds/?/log"].each do |file|
      puts
      puts "## #{file} ##"
      puts File.read(file)
    end
    FileUtils.rm_rf workdir
  end

  def result(name, seq)
    log = File.read "#{workdir}/jobs/#{name}/builds/#{seq}/log"
    # Explicit array conversion required for 1.9.3
    finished = log.lines.to_a.last.chomp
    finished.split.last
  end

  private

  def dump(instream, prefix='', outstream=$stdout)
    begin
      line = instream.readline
      outstream.puts "#{prefix}#{line}"
    end until instream.eof?
  end

  def download_war(version)
    @warname = "vendor/bundle/jenkins-#{version}.war"
    return if File.exists? warname
    puts "Downloading jenkins #{version} ..."
    FileUtils.mkdir_p 'vendor/bundle'
    if version == "1.532.3"
      file = open "http://ks301030.kimsufi.com/war/#{version}/jenkins.war"
    else
      file = open "http://updates.jenkins-ci.org/download/war/#{version}/jenkins.war"
    end
    FileUtils.cp file.path, warname
  end

  def transitive_dependency(name, version, work='work')
    plugin = "#{work}/plugins/#{name}.hpi"
    return if File.exists? plugin
    puts "Downloading #{name}-#{version} ..."
    FileUtils.mkdir_p "#{work}/plugins"
    file = open "http://mirrors.jenkins-ci.org/plugins/#{name}/#{version}/#{name}.hpi?for=ruby-plugin"
    FileUtils.cp file.path, plugin
  end

end
