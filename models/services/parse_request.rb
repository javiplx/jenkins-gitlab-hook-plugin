require_relative '../exceptions/bad_request_exception'
require_relative '../values/parameters_request_details'
require_relative '../values/payload_request_details'
require_relative '../values/merge_request_details'

module GitlabWebHook
  class ParseRequest
    def from(parameters, request)
      details = ParametersRequestDetails.new(parameters)
      return details if details.valid?

      body = read_request_body(request)
      details = PayloadRequestDetails.new(JSON.parse(body))
      return details if details.valid?

      details = MergeRequestDetails.new(JSON.parse(body))
      throw_bad_request_exception(body, parameters) unless details.valid?
      details
    end

    private

    def read_request_body(request)
      request.body.rewind
      return request.body.read
    rescue
      ''
    end

    def throw_bad_request_exception(body, parameters)
      message = "Canot handle received Gitlab payload or the HTTP parameters #{[parameters.inspect, body].join(',')}"
      raise BadRequestException.new(message)
    end
  end
end
