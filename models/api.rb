require 'sinatra/base'

require_relative 'exceptions/bad_request_exception'
require_relative 'exceptions/configuration_exception'
require_relative 'exceptions/not_found_exception'
require_relative 'use_cases/process_commit'
require_relative 'use_cases/process_delete_commit'
require_relative 'services/parse_request'

include Java

java_import Java.java.util.logging.Logger
java_import Java.java.util.logging.Level

module GitlabWebHook
  class Api < Sinatra::Base
    LOGGER = Logger.getLogger(Api.class.name)

    get '/ping' do
      'Gitlab Web Hook is up and running :-)'
    end

    build_now = lambda do
      process_projects Proc.new { |project, details| BuildNow.new(project).with(details) }
    end
    post '/build_now', &build_now

    private

    def process_projects(action)
      details = parse_request
      messages = details.delete_branch_commit? ? ProcessDeleteCommit.new.with(details) : ProcessCommit.new.with(details, action)
      LOGGER.info(messages.join("\n"))
      messages.join("<br/>")
    rescue BadRequestException => e
      LOGGER.warning(e.message)
      status 400
      e.message
    rescue NotFoundException => e
      LOGGER.warning(e.message)
      status 404
      e.message
    rescue => e
      # avoid method signature warnings
      severe = LOGGER.java_method(:log, [Level, java.lang.String, java.lang.Throwable])
      severe.call(Level::SEVERE, e.message, e)
      status 500
      e.message
    end

    def parse_request
      details = ParseRequest.new.from(request.body.read)
      LOGGER.info("gitlab web hook triggered for repo url #{details.repository_url} and #{details.branch} branch")
      LOGGER.info("with payload: #{details.payload}")
      details
    end
  end
end
