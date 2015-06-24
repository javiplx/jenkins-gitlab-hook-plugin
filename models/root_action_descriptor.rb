require 'jenkins/model/global_descriptor'

class GitlabWebHookRootActionDescriptor < Jenkins::Model::GlobalDescriptor
  # TODO a hook to delete artifacts from the feature branches would be nice

  AUTOMATIC_PROJECT_CREATION_PROPERTY = 'automatic_project_creation'
  MASTER_BRANCH_PROPERTY = 'master_branch'
  USE_MASTER_PROJECT_NAME_PROPERTY = 'use_master_project_name'
  DESCRIPTION_PROPERTY = 'description'

  def automatic_project_creation?
    !!@automatic_project_creation
  end

  def master_branch
    @master_branch || "master"
  end

  def use_master_project_name?
    !!@use_master_project_name
  end

  def description
    @description || "Automatically created by Gitlab Web Hook plugin"
  end

  # TODO: make private after merging
  def load_xml(xmlroot)
      @automatic_project_creation   = read_property(xmlroot, AUTOMATIC_PROJECT_CREATION_PROPERTY) == "true"
      @use_master_project_name      = read_property(xmlroot, USE_MASTER_PROJECT_NAME_PROPERTY) == "true"
      @master_branch                = read_property(xmlroot, MASTER_BRANCH_PROPERTY)
      @description                  = read_property(xmlroot, DESCRIPTION_PROPERTY)
      @templates                    = get_templates xmlroot.elements['templates']
      @group_templates              = get_templates xmlroot.elements['group_templates']
      @template                     = xmlroot.elements['template'] && xmlroot.elements['template'].text
  end

  # TODO: make private after merging
  def store_xml(xmlroot)

    write_property(xmlroot, AUTOMATIC_PROJECT_CREATION_PROPERTY, automatic_project_creation?)
    write_property(xmlroot, MASTER_BRANCH_PROPERTY, master_branch)
    write_property(xmlroot, USE_MASTER_PROJECT_NAME_PROPERTY, use_master_project_name?)
    write_property(xmlroot, DESCRIPTION_PROPERTY, description)

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

  def parse(form)
    @automatic_project_creation = form[AUTOMATIC_PROJECT_CREATION_PROPERTY] ? true : false
    if automatic_project_creation?
      @master_branch              = form[AUTOMATIC_PROJECT_CREATION_PROPERTY][MASTER_BRANCH_PROPERTY]
      @use_master_project_name    = form[AUTOMATIC_PROJECT_CREATION_PROPERTY][USE_MASTER_PROJECT_NAME_PROPERTY]
      @description                = form[AUTOMATIC_PROJECT_CREATION_PROPERTY][DESCRIPTION_PROPERTY]
    end
    @template = form['template']
    @templates = form['templates'] && form2list( form['templates'] ).inject({}) do |hash, item|
      hash.update( item['string'] => item['project'] )
    end
    @group_templates = form['group_templates'] && form2list( form['group_templates'] ).inject({}) do |hash, item|
      hash.update( item['string'] => item['project'] )
    end
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

  def read_property(docroot, property)
    docroot.elements[property].text
  end

  def write_property(docroot, property, value)
    docroot.add_element(property).add_text(value.to_s)
  end
end
