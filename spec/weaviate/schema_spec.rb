# frozen_string_literal: true

require "spec_helper"

RSpec.describe Weaviate::Schema do
  let(:client) {
    Weaviate::Client.new(
      scheme: "http",
      host: "localhost:8080",
      model_service: :openai,
      model_service_api_key: "123"
    )
  }
  let(:schema) { client.schema }
  let(:class_fixture) { JSON.parse(File.read("spec/fixtures/class.json")) }
  let(:classes_fixture) { JSON.parse(File.read("spec/fixtures/classes.json")) }
  let(:shard_fixture) { JSON.parse(File.read("spec/fixtures/shards.json")) }

  describe "list" do
    let(:response) { OpenStruct.new(body: classes_fixture) }

    before do
      allow_any_instance_of(Faraday::Connection).to receive(:get)
        .with("schema")
        .and_return(response)
    end

    it "returns the schema" do
      expect(schema.list).to be_a(Weaviate::Response::Collection)
    end
  end

  describe "get" do
    let(:response) { OpenStruct.new(success?: true, body: class_fixture) }

    before do
      allow_any_instance_of(Faraday::Connection).to receive(:get)
        .with("schema/Question")
        .and_return(response)
    end

    it "returns the schema" do
      expect(schema.get(class_name: "Question")).to be_a(Weaviate::Response::Class)
    end
  end

  describe "create" do
    let(:response) { OpenStruct.new(success?: true, body: class_fixture) }

    before do
      allow_any_instance_of(Faraday::Connection).to receive(:post)
        .with("schema")
        .and_return(response)
    end

    it "returns the schema" do
      expect(schema.create(
        class_name: "Question",
        description: "Information from a Jeopardy! question",
        properties: [
          {
            dataType: ["text"],
            description: "The question",
            name: "question"
          }, {
            dataType: ["text"],
            description: "The answer",
            name: "answer"
          }, {
            dataType: ["text"],
            description: "The category",
            name: "category"
          }
        ]
      )).to be_a(Weaviate::Response::Class)
    end
  end

  describe "delete" do
    let(:response) { OpenStruct.new(success?: true, body: "") }

    before do
      allow_any_instance_of(Faraday::Connection).to receive(:delete)
        .with("schema/Question")
        .and_return(response)
    end

    it "returns the schema" do
      expect(schema.delete(
        class_name: "Question"
      )).to be_equal(true)
    end
  end

  describe "update" do
    let(:response) { OpenStruct.new(success?: true, body: class_fixture) }

    before do
      allow_any_instance_of(Faraday::Connection).to receive(:put)
        .with("schema/Question")
        .and_return(response)
    end

    it "returns the schema" do
      expect(schema.update(
        class_name: "Question",
        description: "Information from a Wheel of Fortune question"
      )).to be_a(Weaviate::Response::Class)
    end
  end

  describe "shards" do
    let(:response) { OpenStruct.new(success?: true, body: shard_fixture) }

    before do
      allow_any_instance_of(Faraday::Connection).to receive(:get)
        .with("schema/Question/shards")
        .and_return(response)
    end

    it "returns the schema" do
      expect(schema.shards(class_name: "Question")).to be_equal(shard_fixture)
    end
  end

  describe "update_shard_status" do
    let(:response) { OpenStruct.new(success?: true, body: shard_fixture) }

    before do
      allow_any_instance_of(Faraday::Connection).to receive(:put)
        .with("schema/Question/shards/xyz123")
        .and_return(response)
    end

    it "returns the schema" do
      expect(schema.update_shard_status(
        class_name: "Question",
        shard_name: "xyz123",
        status: "READONLY"
      )).to be_equal(shard_fixture)
    end

    it "raises the error if invalid status: is passed in" do
      expect {
        schema.update_shard_status(
          class_name: "Question",
          shard_name: "xyz123",
          status: "NOTAVAILABLE"
        )
      }.to raise_error(ArgumentError)
    end
  end
end
