# frozen_string_literal: true

require "spec_helper"

RSpec.describe Weaviate::Client do
  let(:client) {
    described_class.new(
      url: "http://localhost:8080",
      model_service: :openai,
      model_service_api_key: "123"
    )
  }

  describe "#initialize" do
    it "creates a client" do
      expect(client).to be_a(Weaviate::Client)
    end

    it "accepts a custom logger" do
      logger = Logger.new($stdout)
      client = described_class.new(
        url: "localhost:8080",
        api_key: "123",
        logger: logger
      )
      expect(client.logger).to eq(logger)
    end
  end

  describe "#collections" do
    it "returns a collections client" do
      expect(client.collections).to be_a(Weaviate::Collections)
    end
  end

  describe "#schema" do
    it "returns a collections client" do
      expect(client.schema).to be_a(Weaviate::Collections)
    end
  end

  describe "#connection" do
    it "sends the auth and model service headers" do
      client = described_class.new(
        url: "http://localhost:8080",
        api_key: "abc",
        model_service: :openai,
        model_service_api_key: "123"
      )

      expect(client.connection.url).to eq("http://localhost:8080/v1")
      expect(client.connection.headers).to eq(
        "User-Agent" => "weaviate-ruby/#{Weaviate::VERSION}",
        "Authorization" => "Bearer abc",
        "X-OpenAI-Api-Key" => "123"
      )
    end

    it "merges custom headers over the defaults" do
      client = described_class.new(
        url: "http://localhost:8080",
        model_service: :google_studio,
        model_service_api_key: "goog",
        headers: {"X-Aws-Access-Key" => "aws-access", "X-Aws-Secret-Key" => "aws-secret"}
      )

      expect(client.connection.headers).to include(
        "X-Goog-Studio-Api-Key" => "goog",
        "X-Aws-Access-Key" => "aws-access",
        "X-Aws-Secret-Key" => "aws-secret"
      )
    end

    it "passes the timeouts" do
      client = described_class.new(url: "http://localhost:8080", open_timeout: 2, read_timeout: 30)

      expect(client.connection.timeouts).to eq(open_timeout: 2, read_timeout: 30)
    end

    it "accepts a proxy" do
      client = described_class.new(url: "http://localhost:8080", proxy: "http://user:pass@proxy.local:8888")

      expect(client.connection.proxy.host).to eq("proxy.local")
      expect(client.connection.proxy.port).to eq(8888)
    end
  end

  describe "#meta" do
    let(:fixture) { JSON.parse(File.read("spec/fixtures/meta.json")) }
    let(:response) { OpenStruct.new(body: fixture) }

    before do
      allow_any_instance_of(Weaviate::Connection).to receive(:get)
        .with("meta")
        .and_return(response)
    end

    it "returns meta information" do
      response = client.meta
      expect(response).to be_a(Hash)
      expect(response["hostname"]).to eq("http://[::]:8080")
    end
  end

  describe "#objects" do
    it "returns an objects client" do
      expect(client.objects).to be_a(Weaviate::Objects)
    end
  end

  describe "#query" do
    it "returns a query client" do
      expect(client.query).to be_a(Weaviate::Query)
    end
  end

  describe "#ready?" do
    let(:response) { OpenStruct.new(status: 200) }

    before do
      allow_any_instance_of(Weaviate::Connection).to receive(:get)
        .with(".well-known/ready")
        .and_return(response)
    end

    it "returns a query client" do
      expect(client.ready?).to eq(true)
    end
  end

  describe "#live?" do
    let(:response) { OpenStruct.new(status: 200) }

    before do
      allow_any_instance_of(Weaviate::Connection).to receive(:get)
        .with(".well-known/live")
        .and_return(response)
    end

    it "returns a query client" do
      expect(client.live?).to eq(true)
    end
  end

  describe "#classifications" do
    it "returns a classifications client" do
      expect(client.classifications).to be_a(Weaviate::Classifications)
    end
  end

  describe "#backups" do
    it "returns a backups client" do
      expect(client.backups).to be_a(Weaviate::Backups)
    end
  end

  describe "#oidc" do
    let(:fixture) { JSON.parse(File.read("spec/fixtures/oidc.json")) }
    let(:response) { OpenStruct.new(body: fixture) }

    before do
      allow_any_instance_of(Weaviate::Connection).to receive(:get)
        .with(".well-known/openid-configuration")
        .and_return(response)
    end

    it "returns an oidc client" do
      response = client.oidc
      expect(response).to be_a(Hash)
      expect(response["cliendID"]).to eq("my-weaviate-client")
    end
  end
end
