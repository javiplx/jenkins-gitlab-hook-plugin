module Jenkins::Triggers
  class TriggerProxy < Java.hudson.triggers.Trigger
    include Jenkins::Model::DescribableProxy
    proxy_for Jenkins::Triggers::Trigger

    def getProjectActions
      @object.project_actions.collect{ |action| @plugin.export(action) }
    end

    def start(project, new_instance)
      @object.job = project
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
