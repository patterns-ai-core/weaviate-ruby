# frozen_string_literal: true

require "spec_helper"
require "logger"
require "stringio"

RSpec.describe Weaviate::Connection do
  let(:log) { StringIO.new }
  let(:connection) {
    described_class.new(
      url: "http://localhost:8080/v1/",
      headers: {"Authorization" => "Bearer secret", "X-OpenAI-Api-Key" => "sk-secret", "X-Databricks-Token" => "dapi-value-1", "X-Aws-Secret-Key" => "aws-value-2"},
      logger: Logger.new(log)
    )
  }

  def http_response(klass, code, body: nil, content_type: "application/json")
    response = klass.new("1.1", code.to_s, "Message")
    response["Content-Type"] = content_type
    response.instance_variable_set(:@body, body)
    response.instance_variable_set(:@read, true)
    response
  end

  def stub_http(response)
    http = instance_double(Net::HTTP)
    allow(http).to receive(:request) do |req|
      @captured_request = req
      response
    end
    allow(Net::HTTP).to receive(:start) do |*args, **kwargs, &block|
      @start_args = args
      @start_kwargs = kwargs
      block.call(http)
    end
  end

  it "sends query params and parses JSON responses" do
    stub_http(http_response(Net::HTTPOK, 200, body: '{"objects": []}'))

    response = connection.get("objects") do |req|
      req.params["class"] = "Question"
      req.params["limit"] = 10
    end

    expect(@captured_request).to be_a(Net::HTTP::Get)
    expect(@captured_request.path).to eq("/v1/objects?class=Question&limit=10")
    expect(@captured_request["Authorization"]).to eq("Bearer secret")
    expect(@start_args.first(3)).to eq(["localhost", 8080, :ENV])
    expect(@start_kwargs).to eq(use_ssl: false)
    expect(response.success?).to eq(true)
    expect(response.status).to eq(200)
    expect(response.body).to eq("objects" => [])
  end

  it "encodes hash bodies as JSON and passes string bodies through" do
    stub_http(http_response(Net::HTTPOK, 200, body: "{}"))

    connection.post("objects") { |req| req.body = {"class" => "Question"} }
    expect(@captured_request.body).to eq('{"class":"Question"}')
    expect(@captured_request["Content-Type"]).to eq("application/json")

    connection.post("schema/Question/tenants") { |req| req.body = '[{"name": "a"}]' }
    expect(@captured_request.body).to eq('[{"name": "a"}]')
  end

  it "returns an empty string body for empty responses" do
    stub_http(http_response(Net::HTTPNoContent, 204, content_type: nil))

    response = connection.delete("objects/Question/123")
    expect(response.status).to eq(204)
    expect(response.body).to eq("")
  end

  it "raises an error for 4xx responses" do
    stub_http(http_response(Net::HTTPNotFound, 404, body: '{"error": [{"message": "not found"}]}'))

    expect { connection.get("schema/Missing") }.to raise_error(Weaviate::ResourceNotFound) { |e|
      expect(e).to be_a(Weaviate::ClientError)
      expect(e).to be_a(Weaviate::Error)
      expect(e.status).to eq(404)
      expect(e.body).to eq("error" => [{"message" => "not found"}])
    }
  end

  it "raises an error for 5xx responses" do
    stub_http(http_response(Net::HTTPServiceUnavailable, 503, body: ""))

    expect { connection.get(".well-known/ready") }.to raise_error(Weaviate::ServerError)
  end

  it "wraps connection failures" do
    allow(Net::HTTP).to receive(:start).and_raise(Errno::ECONNREFUSED)

    expect { connection.get("meta") }.to raise_error(Weaviate::ConnectionFailed)
  end

  it "wraps timeouts" do
    allow(Net::HTTP).to receive(:start).and_raise(Net::ReadTimeout)

    expect { connection.get("meta") }.to raise_error(Weaviate::TimeoutError)
  end

  it "passes timeouts to Net::HTTP" do
    connection = described_class.new(url: "http://localhost:8080/v1", open_timeout: 2, read_timeout: 30)
    stub_http(http_response(Net::HTTPOK, 200, body: "{}"))

    connection.get("meta")

    expect(@start_kwargs).to eq(use_ssl: false, open_timeout: 2, read_timeout: 30)
  end

  it "connects through the configured proxy" do
    connection = described_class.new(url: "https://example.weaviate.network/v1", proxy: "http://user:pass@proxy.local:8888")
    stub_http(http_response(Net::HTTPOK, 200, body: "{}"))

    connection.get("meta")

    expect(@start_args).to eq(["example.weaviate.network", 443, "proxy.local", 8888, "user", "pass"])
    expect(@start_kwargs).to eq(use_ssl: true)
  end

  it "filters secrets from the logs" do
    stub_http(http_response(Net::HTTPOK, 200, body: "{}"))

    connection.get("meta")

    expect(log.string).to include("GET http://localhost:8080/v1/meta")
    expect(log.string).to include("authorization: [FILTERED]")
    expect(log.string).to include("x-openai-api-key: [FILTERED]")
    expect(log.string).to include("x-databricks-token: [FILTERED]")
    expect(log.string).to include("x-aws-secret-key: [FILTERED]")
    %w[Bearer\ secret sk-secret dapi-value-1 aws-value-2].each do |value|
      expect(log.string).not_to include(value)
    end
  end
end
