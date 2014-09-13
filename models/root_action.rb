
require 'gitlab_web_hook/exceptions'

require_relative 'unprotected_root_action'
require 'sinatra/base'

require_relative 'values/payload_request_details'
require_relative 'use_cases/process_commit'
require_relative 'use_cases/process_delete_commit'

module GitlabWebHook
 class RootAction < Jenkins::Model::UnprotectedRootAction

  WEB_HOOK_ROOT_URL = "gitlab"

  display_name "Gitlab Web Hook"
  icon nil # we don't need the link in the main navigation
  url_path WEB_HOOK_ROOT_URL

  def call(env)

    logger = env['jruby.rack.context']
    response = env['java.servlet_response']

    payload = JSON.parse( env['rack.input'].read )
    details = PayloadRequestDetails.new(payload)
    raise BadRequestException.new("Bad payload : #{payload}") unless details.valid?
    messages = details.delete_branch_commit? ? ProcessDeleteCommit.new.with(details) : ProcessCommit.new.with(details)

  rescue BadRequestException => e
    logger.log("WARNING", e.to_s)
    response.status = 400
  rescue NotFoundException => e
    logger.log("WARNING", e.to_s)
    response.status = 404
  rescue => e
    logger.log("ERROR", "Internal Server error. Backtrace :\n#{e.full_message}")
    response.status = 500
  end
 end
end

Jenkins::Plugin.instance.register_extension(GitlabWebHook::RootAction.new)
