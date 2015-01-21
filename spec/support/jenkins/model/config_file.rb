
module Jenkins
  module Model
    class DefaultDescriptor
      def configFile
        self
      end
      def file
        self
      end
      def exists
        false
      end
      def self.java_class
        self
      end
    end
  end
end

require 'models/root_action_descriptor'

