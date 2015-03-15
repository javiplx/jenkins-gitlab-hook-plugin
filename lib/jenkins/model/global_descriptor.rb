require 'rexml/document'
require 'jenkins/model/descriptor'

module Jenkins::Model
  class GlobalDescriptor < Jenkins::Model::DefaultDescriptor

    java_import Java.hudson.BulkChange
    java_import Java.hudson.model.listeners.SaveableListener

    def initialize(impl, plugin, java_type)
      super
      load
    end

    def load
      return unless configFile.file.exists()
      xmlfile = File.new(configFile.file.canonicalPath)
      xmldoc = REXML::Document.new(xmlfile)
      load_xml(xmldoc.root) if xmldoc.root
    end

    def configure(req, form)
      parse(form)
      save
    end

    def save
      return if BulkChange.contains(self)

      doc = REXML::Document.new
      doc.add_element( 'hudson.model.Descriptor' , { "plugin" => Jenkins::Plugin.instance.name } )

      store_xml doc.root

      f = File.open(configFile.file.canonicalPath, 'wb')
      f.puts("<?xml version='#{doc.version}' encoding='#{doc.encoding}'?>")

      formatter = REXML::Formatters::Pretty.new
      formatter.compact = true
      formatter.write doc, f

      f.close

      SaveableListener.fireOnChange(self, configFile)
      f.closed?
    end

    private

    def load_xml(xmlroot)
      raise Exception.new("load_xml is an abstract method")
    end

    def store_xml(xmlroot)
      raise Exception.new("store_xml is an abstract method")
    end

    def parse(form)
      raise Exception.new("parse is an abstract method")
    end
  end
end
