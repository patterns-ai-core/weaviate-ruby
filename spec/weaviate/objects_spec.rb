# frozen_string_literal: true

require "spec_helper"

RSpec.describe Weaviate::Objects do
  let(:client) {
    Weaviate::Client.new(
      scheme: "http",
      host: "localhost:8080",
      model_service: :openai,
      model_service_api_key: "123"
    )
  }
  let(:objects) { client.objects }
  let(:object_fixture) { JSON.parse(File.read("spec/fixtures/object.json")) }
  let(:objects_fixture) { JSON.parse(File.read("spec/fixtures/objects.json")) }

  describe "#create" do
    let(:response) { OpenStruct.new(success?: true, body: object_fixture) }

    before do
      allow_any_instance_of(Faraday::Connection).to receive(:post)
        .with("objects")
        .and_return(response)
    end

    it "creates an object" do
      expect(objects.create(
        class_name: "Question",
        properties: {
          answer: "42",
          question: "What is the meaning of life?",
          category: "philosophy"
        }
      )).to be_a(Weaviate::Response::Object)
    end
  end

  describe "#list" do
    let(:response) { OpenStruct.new(body: objects_fixture) }

    before do
      allow_any_instance_of(Faraday::Connection).to receive(:get)
        .with("objects")
        .and_return(response)
    end

    it "returns objects" do
      response = objects.list
      expect(response).to be_a(Weaviate::Response::Collection)
      expect(response.total_results).to eq(1)
    end
  end

  describe "#get" do
    let(:response) { OpenStruct.new(success?: true, body: object_fixture) }

    before do
      allow_any_instance_of(Faraday::Connection).to receive(:get)
        .with("objects/Question/123")
        .and_return(response)
    end

    it "gets an object" do
      expect(objects.get(
        class_name: "Question",
        id: "123"
      )).to be_a(Weaviate::Response::Object)
    end
  end

  describe "#delete" do
    let(:response) { OpenStruct.new(success?: true, body: "") }

    before do
      allow_any_instance_of(Faraday::Connection).to receive(:delete)
        .with("objects/Question/123")
        .and_return(response)
    end

    it "deletes an object" do
      expect(objects.delete(
        class_name: "Question",
        id: "123"
      )).to be_equal(true)
    end
  end

  describe "#update" do
    let(:response) { OpenStruct.new(success?: true, body: object_fixture) }

    before do
      allow_any_instance_of(Faraday::Connection).to receive(:put)
        .with("objects/Question/123")
        .and_return(response)
    end

    it "returns the schema" do
      expect(objects.update(
        class_name: "Question",
        id: "123",
        properties: {
          question: "What does 6 times 7 equal to?",
          category: "math",
          answer: "42"
        }
      )).to be_a(Weaviate::Response::Object)
    end
  end

  describe "#batch_create" do
    let(:response) { OpenStruct.new(success?: true, body: objects_fixture) }

    before do
      allow_any_instance_of(Faraday::Connection).to receive(:post)
        .with("batch/objects")
        .and_return(response)
    end

    it "batch creates objects" do
      expect(objects.batch_create(objects: [
        {
          class_name: "Question",
          properties: {
            answer: "42",
            question: "What is the meaning of life?",
            category: "philosophy"
          }
        }, {
          class_name: "Question",
          properties: {
            answer: "42",
            question: "What does 6 times 7 equal to?",
            category: "math"
          }
        }
      ])).to be_a(Weaviate::Response::Collection)
    end
  end
end
