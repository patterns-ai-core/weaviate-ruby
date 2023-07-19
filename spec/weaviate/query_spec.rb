# frozen_string_literal: true

require "spec_helper"
require "graphlient"

RSpec.describe Weaviate::Query do
  let(:client) {
    Weaviate::Client.new(
      url: "http://localhost:8080",
      model_service: :openai,
      model_service_api_key: "123"
    )
  }
  let(:query) { client.query }

  describe "#get" do
    let(:response) {
      double(original_hash: {
        "data" => {
          "Get" => {
            "Question" => [
              {
                "category" => "SCIENCE",
                "question" => "In 1953 Watson & Crick built a model of the molecular structure of this, the gene-carrying substance"
              }
            ]
          }
        }
      })
    }

    let(:graphql_query) {
      <<-GRAPHQL
        query {
          Get {
            Question(nearText: { concepts: ["biology"] }, limit: 1) {
              question
              category
            }
          }
        }
      GRAPHQL
    }

    before do
      allow_any_instance_of(Graphlient::Client).to receive(:parse)
        .and_return(graphql_query)

      allow_any_instance_of(Graphlient::Client).to receive(:execute)
        .and_return(response)
    end

    it "returns the query" do
      data = query.get(
        class_name: "Question",
        fields: "question, category",
        near_text: "{ concepts: [\"biology\"] }",
        tenant: "tenant_name",
        limit: "1"
      )

      expect(data.count).to eq(1)
      expect(data.first["category"]).to eq("SCIENCE")
      expect(data.first["question"]).to eq("In 1953 Watson & Crick built a model of the molecular structure of this, the gene-carrying substance")
    end
  end

  describe "#aggs" do
    let(:response) {
      double(original_hash: {
        "data" => {
          "Aggregate" => {
            "Question" => [
              {
                "category" => "SCIENCE",
                "question" => "In 1953 Watson & Crick built a model of the molecular structure of this, the gene-carrying substance"
              }
            ]
          }
        }
      })
    }

    let(:graphql_query) {
      <<-GRAPHQL
        query {
          Aggregate {
            Question(nearText: { concepts: ["biology"] }) {
              meta {
                count
              }
            }
          }
        }
      GRAPHQL
    }

    before do
      allow_any_instance_of(Graphlient::Client).to receive(:parse)
        .and_return(graphql_query)

      allow_any_instance_of(Graphlient::Client).to receive(:execute)
        .and_return(response)
    end

    it "returns the query" do
      data = query.aggs(
        class_name: "Question",
        fields: "question, category",
        near_text: "{ concepts: [\"biology\"] }"
      )

      expect(data.count).to eq(1)
      expect(data.first["category"]).to eq("SCIENCE")
      expect(data.first["question"]).to eq("In 1953 Watson & Crick built a model of the molecular structure of this, the gene-carrying substance")
    end
  end

  describe "#explore" do
    let(:response) {
      double(original_hash: {
        "data" => {
          "Explore" => [{"certainty" => "0.9999", "class_name" => "Question"}]
        }
      })
    }

    let(:graphql_query) {
      <<-GRAPHQL
        query {
          Explore(
            limit: 1
            nearText: { concepts: ["biology"] }
          ) {
            certainty
            className
          }
        }
      GRAPHQL
    }

    before do
      allow_any_instance_of(Graphlient::Client).to receive(:parse)
        .and_return(graphql_query)

      allow_any_instance_of(Graphlient::Client).to receive(:execute)
        .and_return(response)
    end

    it "returns the query" do
      response = query.explore(
        fields: "certainty className",
        near_text: "{ concepts: [\"biology\"] }",
        limit: "1"
      )

      expect(response.count).to eq(1)
      expect(response.first["certainty"]).to eq("0.9999")
      expect(response.first["class_name"]).to eq("Question")
    end
  end
end
