require_relative '../exceptions/bad_request_exception'
require_relative '../values/payload_request_details'

module GitlabWebHook
  class ParseRequest
    def from(payload)
      message = "repo url not found in Gitlab payload #{payload}"
      details = PayloadRequestDetails.new(JSON.parse(payload))
      raise BadRequestException.new(message) unless details.valid?
      details
    end
  end
end
