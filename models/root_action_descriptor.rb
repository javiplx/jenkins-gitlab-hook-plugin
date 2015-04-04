require 'jenkins/model/global_descriptor'

class GitlabWebHookRootActionDescriptor < Jenkins::Model::GlobalDescriptor

    def automatic_project_creation?
      automatic_project_creation
    end

    def master_branch
      @master_branch || "master"
    end

    def use_master_project_name?
      use_master_project_name
    end

    def description
      @description || "Automatically created by Gitlab Web Hook plugin"
    end

    def any_branch_pattern
      @any_branch_pattern || "**"
    end

    def templated_jobs
      @templates || {}
    end

    def templated_groups
      @group_templates || {}
    end

    def template_fallback
      @template
    end

    private

    def load_xml(xmlroot)
      @automatic_project_creation = xmlroot.elements['automatic_project_creation'].text == "true" ? true : false
      @use_master_project_name = xmlroot.elements['use_master_project_name'].text == "true" ? true : false

      @master_branch = xmlroot.elements['master_branch'].text
      @description = xmlroot.elements['description'].text
      @any_branch_pattern = xmlroot.elements['any_branch_pattern'].text

      @templates = get_templates xmlroot.elements['templates']
      @group_templates = get_templates xmlroot.elements['group_templates']
      @template = xmlroot.elements['template'] && xmlroot.elements['template'].text
    end

    def store_xml(xmlroot)
      xmlroot.add_element( 'automatic_project_creation' ).add_text( automatic_project_creation.to_s )
      xmlroot.add_element( 'master_branch' ).add_text( master_branch )
      xmlroot.add_element( 'use_master_project_name' ).add_text( use_master_project_name.to_s )
      xmlroot.add_element( 'description' ).add_text( description )
      xmlroot.add_element( 'any_branch_pattern' ).add_text( any_branch_pattern )

      xmlroot.add_element( 'template' ).add_text( template_fallback )

      tpls = xmlroot.add_element( 'templates' )
      templated_jobs.each do |k,v|
        new = tpls.add_element('template')
        new.add_element('string').add_text(k)
        new.add_element('project').add_text(v)
      end

      tpls = xmlroot.add_element( 'group_templates' )
      templated_groups.each do |k,v|
        new = tpls.add_element('template')
        new.add_element('string').add_text(k)
        new.add_element('project').add_text(v)
      end
    end

    def parse(form)
      @automatic_project_creation = form["autocreate"] ? true : false
      if automatic_project_creation?
        @master_branch              = form["autocreate"]["master_branch"]
        @use_master_project_name    = form["autocreate"]["use_master_project_name"]
        @description                = form["autocreate"]["description"]
        @any_branch_pattern         = form["autocreate"]["any_branch_pattern"]
      end
      @template = form['template']
      @templates = form['templates'] && form2list( form['templates'] ).inject({}) do |hash, item|
        hash.update( item['string'] => item['project'] )
      end
      @group_templates = form['group_templates'] && form2list( form['group_templates'] ).inject({}) do |hash, item|
        hash.update( item['string'] => item['project'] )
      end
    end

    def automatic_project_creation
      @automatic_project_creation.nil? ? false : @automatic_project_creation
    end

    def use_master_project_name
      @use_master_project_name.nil? ? false : @use_master_project_name
    end

    def form2list(form_item)
      form_item.is_a?(Java::NetSfJson::JSONArray) ? form_item : [].push( form_item )
    end

    def get_templates(templates)
      return unless templates
      templates.elements.select{ |tpl| tpl.name == 'template' }.inject({}) do |hash, tpl|
        hash[tpl.elements['string'].text] = tpl.elements['project'].text
        hash
      end
    end

end
