
require_relative 'unprotected_root_action'
require 'sinatra/base'

require_relative 'exceptions/bad_request_exception'
require_relative 'exceptions/not_found_exception'

require_relative 'values/payload_request_details'
require_relative 'use_cases/process_commit'
require_relative 'use_cases/process_delete_commit'

include Java
java_import Java.java.util.logging.Logger

module GitlabWebHook
 class RootAction < Jenkins::Model::UnprotectedRootAction

  LOGGER = Logger.getLogger(RootAction.class.name)

  WEB_HOOK_ROOT_URL = "gitlab"

  display_name "Gitlab Web Hook"
  icon nil # we don't need the link in the main navigation
  url_path WEB_HOOK_ROOT_URL

  def call(env)
    payload = JSON.parse( env['rack.input'].read )
    details = PayloadRequestDetails.new(payload)
    raise BadRequestException.new("Bad payload : #{payload}") unless details.valid?
    messages = details.delete_branch_commit? ? ProcessDeleteCommit.new.with(details) : ProcessCommit.new.with(details)
  rescue BadRequestException => e
    LOGGER.warning(e.to_s)
    env['java.servlet_response'].status = 400
  rescue NotFoundException => e
    LOGGER.warning(e.to_s)
    env['java.servlet_response'].status = 404
  rescue => e
    LOGGER.severe("Internal Server error. Backtrace :\n#{e.full_message}")
    env['java.servlet_response'].status = 500
  end
 end
end

Jenkins::Plugin.instance.register_extension(GitlabWebHook::RootAction.new)
