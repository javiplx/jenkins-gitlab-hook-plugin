module Jenkins::Triggers
  class TriggerProxy < Java.hudson.triggers.Trigger
    include Jenkins::Model::DescribableProxy
    proxy_for Jenkins::Triggers::Trigger

    field_reader :job

    def start(project, new_instance)
      java_start = java_class.java_instance_methods.find{ |method| method.name == 'start' }
      java_start.invoke(self, project, new_instance)
      @object.start(project, new_instance)
    end

    def run
      @object.run
    end

    def stop
      @object.stop
    end
  end
end
