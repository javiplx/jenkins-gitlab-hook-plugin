require 'jenkins/model'

module Jenkins
  module Triggers
    # Triggers a Build.
    # {http://javadoc.jenkins-ci.org/hudson/triggers/Trigger.html}
    class Trigger
      include Jenkins::Model
      include Jenkins::Model::Describable
      describe_as Java.hudson.triggers.Trigger, :with => Jenkins::Triggers::TriggerDescriptor

      # Executes the triggered task.
      #
      # This method is invoked when Trigger.new(String) is used
      # to create an instance, and the crontab matches the current time.
      def run
      end

      # Called when a Trigger is loaded into memory and started.
      #
      # @param [Item]
      #      given so that the persisted form of this object won't have to have a back pointer.
      # @param [Boolean]
      #      True if this may be a newly created trigger (when project is created or configured).
      #      False if this is invoked for a Project loaded from disk.
      def start(project, new_instance)
      end

      # Called before a Trigger is removed.
      # Under some circumstances, this may be invoked more than once for
      # a given Trigger, so be prepared for that.
      #
      # When the configuration is changed for a project, all triggers
      # are removed once and then added back.
      def stop
      end
    end
  end
end
