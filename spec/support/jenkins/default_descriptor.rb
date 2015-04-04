
# explicitly require stuff from models root folder for proper inheritance
if RUBY_PLATFORM == 'java'
  require 'jenkins/model/global_descriptor'
end

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

