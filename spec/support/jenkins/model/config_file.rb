
require 'jenkins/model/global_descriptor'

module Jenkins
  module Model
    class GlobalDescriptor
      def configFile
        self
      end
      def file
        self
      end
      def exists
        false
      end
    end
  end
end

