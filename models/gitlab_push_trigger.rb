require 'jenkins/triggers'

class GitlabPushTrigger < Jenkins::Triggers::Trigger

  display_name "Trigger when changes are pushed to GitLab"

  def do_poll_and_run(triggered_by)
    get_descriptor.queue.execute(PollRunner.new(self))
  end

  def project_actions
    [ GitlabPollAction.new(job)]
  end

  def self.applicable?(type)
    type.is_a? Java::HudsonModel::Project
  end

  class DescriptorImpl < Jenkins::Triggers::TriggerDescriptor
    java_import Java.hudson.util.SequentialExecutionQueue
    java_import Java.jenkins.model.Jenkins

    def queue
      # Seems the same than Jenkins.instance.queue
      @queue ||= SequentialExecutionQueue.new(Jenkins::MasterComputer.threadPoolForRemoting)
    end
  end

  describe_as Java.hudson.triggers.Trigger, :with => DescriptorImpl

  private

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
