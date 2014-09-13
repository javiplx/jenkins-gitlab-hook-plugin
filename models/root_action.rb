
require_relative 'unprotected_root_action'
require_relative 'api'

module GitlabWebHook
 class RootAction < Jenkins::Model::UnprotectedRootAction

  WEB_HOOK_ROOT_URL = "gitlab"

  display_name "Gitlab Web Hook"
  icon nil # we don't need the link in the main navigation
  url_path WEB_HOOK_ROOT_URL

  def call(env)
    Api.new.call(env)
  end
 end
end

Jenkins::Plugin.instance.register_extension(GitlabWebHook::RootAction.new)
