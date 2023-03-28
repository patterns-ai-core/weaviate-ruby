# frozen_string_literal: true

require "spec_helper"
require "graphlient"

RSpec.describe Weaviate::Query do
  let(:client) {
    Weaviate::Client.new(
      scheme: "https",
      host: "localhost:8080",
      model_service: :openai,
      model_service_api_key: "123"
    )
  }
  let(:query) { client.query }

  describe "#get" do
    let(:response) {
      double(
        data: double(
          get: double(
            question: [double(category: "SCIENCE", question: "In 1953 Watson & Crick built a model of the molecular structure of this, the gene-carrying substance")]
          )
        )
      )
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
        fields: ["question", "category"],
        near_text: {concepts: ["biology"]},
        limit: 1
      )

      expect(data.count).to eq(1)
      expect(data.first.category).to eq("SCIENCE")
      expect(data.first.question).to eq("In 1953 Watson & Crick built a model of the molecular structure of this, the gene-carrying substance")
    end
  end

  describe "WHERE_OPERANDS" do
    it "returns the correct class name" do
      expect(Weaviate::Query::WHERE_OPERANDS[:and].call).to eq(And)
      expect(Weaviate::Query::WHERE_OPERANDS[:or].call).to eq(Or)
      expect(Weaviate::Query::WHERE_OPERANDS[:equal].call).to eq(Equal)
      expect(Weaviate::Query::WHERE_OPERANDS[:not_equal].call).to eq(NotEqual)
      expect(Weaviate::Query::WHERE_OPERANDS[:greater_than].call).to eq(GreaterThan)
      expect(Weaviate::Query::WHERE_OPERANDS[:greater_than_equal].call).to eq(GreaterThanEqual)
      expect(Weaviate::Query::WHERE_OPERANDS[:less_than].call).to eq(LessThan)
      expect(Weaviate::Query::WHERE_OPERANDS[:less_than_equal].call).to eq(LessThanEqual)
      expect(Weaviate::Query::WHERE_OPERANDS[:like].call).to eq(Like)
      expect(Weaviate::Query::WHERE_OPERANDS[:within_geo_range].call).to eq(WithinGeoRange)
      expect(Weaviate::Query::WHERE_OPERANDS[:is_null].call).to eq(IsNull)
    end
  end
end
