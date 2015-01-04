require 'jenkins/triggers'

class GitlabPushTrigger < Jenkins::Triggers::Trigger

  display_name "Trigger when changes are pushed to GitLab"

  def self.applicable?(type)
    type.is_a? Java::HudsonModel::Project
  end

end
