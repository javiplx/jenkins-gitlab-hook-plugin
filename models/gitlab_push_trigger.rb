require 'jenkins/triggers'

class GitlabPushTrigger < Jenkins::Triggers::Trigger

  display_name "Trigger when changes are pushed to GitLab"

  def do_poll_and_run(triggered_by)
    get_descriptor.queue.execute(PollRunner.new)
  end

  def self.applicable?(type)
    type.is_a? Java::HudsonModel::Project
  end

  private

  class PollRunner
    include java.lang.Runnable

    java_import Java.hudson.util.StreamTaskListener

    def run
      listener = Java.hudson.util.StreamTaskListener.new(Java.java.io.File.new("/tmp/poll.log"))
      result = job.poll(listener).has_changes
      listener.close
      puts "Poll done with #{result}"
    rescue java.io.IOException => e
      puts "Failed to record SCM polling: #{e}"
    end

  end

end
