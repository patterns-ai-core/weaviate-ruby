# frozen_string_literal: true

require "spec_helper"

RSpec.describe Weaviate::Classifications do
  let(:client) {
    Weaviate::Client.new(
      scheme: "http",
      host: "localhost:8080"
    )
  }

  let(:classifications) { client.classifications }
  let(:classification_fixture) { JSON.parse(File.read("spec/fixtures/classification.json")) }

  describe "#create" do
    let(:response) { OpenStruct.new(success?: true, body: classification_fixture) }

    before do
      allow_any_instance_of(Faraday::Connection).to receive(:post)
        .with("classifications")
        .and_return(response)
    end

    it "creates the classification" do
      response = classifications.create(
        class_name: "Posts",
        type: "zeroshot",
        classify_properties: ["hasColor"],
        based_on_properties: ["text"]
      )
      expect(response["type"]).to eq("zeroshot")
      expect(response["status"]).to eq("running")
    end
  end

  describe "#get" do
    let(:response) { OpenStruct.new(success?: true, body: classification_fixture) }

    before do
      allow_any_instance_of(Faraday::Connection).to receive(:get)
        .with("classifications/1")
        .and_return(response)
    end

    it "returns the classification" do
      response = classifications.get(id: "1")
      expect(response["id"]).to eq("1")
    end
  end
end
