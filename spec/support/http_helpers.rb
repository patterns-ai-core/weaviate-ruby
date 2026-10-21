# frozen_string_literal: true

# Stubs Net::HTTP and records the requests the client sends, so specs can
# check the HTTP method, path, query and body.
module HTTPHelpers
  def stub_weaviate(status: 200, body: "{}", content_type: "application/json")
    requests = []
    response_class = Net::HTTPResponse::CODE_TO_OBJ.fetch(status.to_s)

    http = instance_double(Net::HTTP)
    allow(http).to receive(:request) do |req|
      requests << req
      response = response_class.new("1.1", status.to_s, "Message")
      response["Content-Type"] = content_type
      response.instance_variable_set(:@body, body)
      response.instance_variable_set(:@read, true)
      response
    end
    allow(Net::HTTP).to receive(:start) { |*_args, **_kwargs, &block| block.call(http) }

    requests
  end

  def request_summary(req)
    [req.method, req.path, req.body && JSON.parse(req.body)]
  end
end

RSpec.configure do |config|
  config.include HTTPHelpers
end
