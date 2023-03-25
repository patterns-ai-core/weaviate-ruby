# frozen_string_literal: true

require "spec_helper"

RSpec.describe Weaviate::Client do
  let(:client) {
    Weaviate::Client.new(
      scheme: "http",
      host: "localhost:8080",
      model_service: :openai,
      model_service_api_key: "123"
    )
  }

  describe "#initialize" do
    it "creates a client" do
      expect(client).to be_a(Weaviate::Client)
    end
  end

  describe "#schema" do
    it "returns a schema client" do
      expect(client.schema).to be_a(Weaviate::Schema)
    end
  end

  describe "#meta" do
    let(:fixture) { JSON.parse(File.read("spec/fixtures/meta.json")) }
    let(:response) { OpenStruct.new(body: fixture) }

    before do
      allow_any_instance_of(Faraday::Connection).to receive(:get)
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

  describe "#oidc" do
    let(:fixture) { JSON.parse(File.read("spec/fixtures/oidc.json")) }
    let(:response) { OpenStruct.new(body: fixture) }

    before do
      allow_any_instance_of(Faraday::Connection).to receive(:get)
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
