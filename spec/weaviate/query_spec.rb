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

      expect(data.first.category).to eq("SCIENCE")
      expect(data.first.question).to eq("In 1953 Watson & Crick built a model of the molecular structure of this, the gene-carrying substance")
    end
  end
end
