require_relative '../services/get_jenkins_projects'

module GitlabWebHook
  class NotifyCommit
    LOGGER = Java.java.util.logging.Logger.getLogger(NotifyCommit.class.name)

    attr_reader :project

    def initialize(project, logger = nil)
      raise ArgumentError.new('project is required') unless project
      @project = project
      @logger = logger
    end

    def call
      return "#{project} is configured to ignore notify commit, skipping scheduling for polling" if project.ignore_notify_commit?
      return "#{project} is not buildable (it is disabled or not saved), skipping polling" unless project.buildable?

      begin
        return "#{project} scheduled for polling" if project.schedulePolling
      rescue java.lang.Exception => e
        # avoid method signature warnings
        severe = logger.java_method(:log, [Java.java.util.logging.Level, java.lang.String, java.lang.Throwable])
        severe.call(Java.java.util.logging.Level::SEVERE, e.message, e)
      end

      "#{project} could not be scheduled for polling, it is disabled or has no SCM trigger"
    end

    private

    def logger
      @logger || LOGGER
    end
  end
end
