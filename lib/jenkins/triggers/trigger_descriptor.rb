module Jenkins::Triggers
  # Descriptor for Trigger
  class TriggerDescriptor < Java.hudson.triggers.TriggerDescriptor
    include Jenkins::Model::Descriptor

    java_import Java.hudson.util.SequentialExecutionQueue
    java_import Java.jenkins.model.Jenkins

    def queue
      # Seems the same than Jenkins.instance.queue
      @queue ||= SequentialExecutionQueue.new(Jenkins::MasterComputer.threadPoolForRemoting)
    end

    # Returns true if this trigger is applicable to the given Item
    #
    # @param [Boolean] true to allow user to configure a trigger for this item
    def isApplicable(targetType)
       # @impl refers to the Ruby class implementing this descriptor
      @impl.respond_to?(:applicable?) ? @impl.applicable?(targetType) : true
    end
  end
end
