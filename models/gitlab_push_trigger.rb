require 'jenkins/triggers'

class GitlabPushTrigger < Jenkins::Triggers::Trigger

  display_name "Trigger when changes are pushed to GitLab"

  def do_poll_and_run(triggered_by)
    get_descriptor.queue.execute(PollRunner.new(self))
  end

  def project_actions
    [ GitlabPollAction.new ]
  end

  def self.applicable?(type)
    type.is_a? Java::HudsonModel::Project
  end

  private

  class GitlabPollAction
    include Jenkins::Model::Action
    display_name "Gitlab Trigger Log"
    icon "clipboard.png"
    url_path "GitlabPollLog"
  end

  class GitlabPollActionProxy
    include Jenkins::Model::ActionProxy
    proxy_for GitlabPollAction
  end

  class PollRunner
    include java.lang.Runnable

    java_import Java.hudson.util.StreamTaskListener

    attr_reader :trigger

    def initialize(trigger)
      @trigger = trigger
    end

    def run
      listener = Java.hudson.util.StreamTaskListener.new(Java.java.io.File.new("/tmp/poll.log"))
      result = trigger.job.poll(listener).has_changes
      listener.close
      puts "Poll done with #{result}"
    rescue java.io.IOException => e
      puts "Failed to record SCM polling: #{e}"
    end

  end

end
