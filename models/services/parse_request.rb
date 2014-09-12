require_relative '../exceptions/bad_request_exception'
require_relative '../values/payload_request_details'

module GitlabWebHook
  class ParseRequest
    def from(request)
      body = read_request_body(request)
      details = PayloadRequestDetails.new(JSON.parse(body))
      throw_bad_request_exception(body) unless details.valid?
      details
    end

    private

    def read_request_body(request)
      request.body.rewind
      return request.body.read
    rescue
      ''
    end

    def throw_bad_request_exception(body)
      message = "repo url not found in Gitlab payload #{body.join(',')}"
      raise BadRequestException.new(message)
    end
  end
end
