# frozen_string_literal: true

require "spec_helper"

RSpec.describe Weaviate::Query do
  let(:client) {
    Weaviate::Client.new(
      url: "http://localhost:8080",
      model_service: :openai,
      model_service_api_key: "123"
    )
  }
  let(:query) { client.query }

  before do
    @captured_query = nil

    allow_any_instance_of(Weaviate::Connection).to receive(:post) do |_, path, &block|
      expect(path).to eq("graphql")
      req = OpenStruct.new(body: nil)
      block.call(req)
      @captured_query = req.body[:query]
      response
    end
  end

  def squish(str)
    str.gsub(/\s+/, " ").strip
  end

  describe "#get" do
    let(:response) {
      OpenStruct.new(body: {
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
      expect(squish(@captured_query)).to eq(
        '{ Get { Question(limit: 1, tenant: "tenant_name", nearText: { concepts: ["biology"] }) { question, category } } }'
      )
    end

    it "omits arguments that were not passed" do
      query.get(
        class_name: "Question",
        fields: "question",
        where: '{ operator: Equal, valueText: "1-dev", path: ["company"] }'
      )

      expect(squish(@captured_query)).to eq(
        '{ Get { Question(where: { operator: Equal, valueText: "1-dev", path: ["company"] }) { question } } }'
      )
    end

    it "omits the argument list entirely when no arguments are passed" do
      query.get(class_name: "Question", fields: "question")

      expect(squish(@captured_query)).to eq("{ Get { Question { question } } }")
    end

    it "quotes the after cursor and supports distance in near_vector" do
      query.get(
        class_name: "Question",
        fields: "question _additional { distance }",
        after: "3c5f7039-37f3-4244-b3e2-8f4a083e448d",
        offset: 0,
        near_vector: "{ vector: [0.1, 0.2], distance: 0.3 }"
      )

      expect(squish(@captured_query)).to eq(
        '{ Get { Question(after: "3c5f7039-37f3-4244-b3e2-8f4a083e448d", offset: 0, nearVector: { vector: [0.1, 0.2], distance: 0.3 }) { question _additional { distance } } } }'
      )
    end

    it "serializes Ruby hashes, arrays and symbols into GraphQL arguments" do
      query.get(
        class_name: "Question",
        fields: "question",
        where: {
          operator: "And",
          operands: [
            {path: ["category"], operator: :Equal, valueText: "Say \"hi\"\n"},
            {path: ["points"], operator: "GreaterThan", valueNumber: 1.5},
            {path: ["active"], operator: :Equal, valueBoolean: true}
          ]
        },
        near_text: {concepts: ["biology"], certainty: 0.7},
        sort: [{path: ["points"], order: "desc"}],
        with_hybrid: {query: "Sweets", alpha: 0.5, fusionType: :relativeScoreFusion}
      )

      expect(squish(@captured_query)).to eq(
        '{ Get { Question(nearText: { concepts: ["biology"], certainty: 0.7 }, ' \
        'hybrid: { query: "Sweets", alpha: 0.5, fusionType: relativeScoreFusion }, ' \
        'where: { operator: And, operands: [{ path: ["category"], operator: Equal, valueText: "Say \\"hi\\"\\n" }, ' \
        '{ path: ["points"], operator: GreaterThan, valueNumber: 1.5 }, { path: ["active"], operator: Equal, valueBoolean: true }] }, ' \
        'sort: [{ path: ["points"], order: desc }]) { question } } }'
      )
    end

    it "quotes strings for enum keys that are not valid enum names" do
      query.get(class_name: "Question", fields: "question", where: {path: ["id"], operator: "Equal) { x", valueText: "a"})

      expect(@captured_query).to include('operator: "Equal) { x"')
    end

    it "rejects keys that are not valid GraphQL names" do
      expect {
        query.get(class_name: "Question", fields: "question", where: {"path) { x" => ["id"]})
      }.to raise_error(ArgumentError, /Invalid GraphQL name/)
    end

    it "passes group_by" do
      query.get(class_name: "Question", fields: "question", near_text: {concepts: ["biology"]}, group_by: {path: ["category"], groups: 2, objectsPerGroup: 3})

      expect(squish(@captured_query)).to eq(
        '{ Get { Question(nearText: { concepts: ["biology"] }, groupBy: { path: ["category"], groups: 2, objectsPerGroup: 3 }) { question } } }'
      )
    end

    context "when the query returns errors" do
      let(:response) {
        OpenStruct.new(body: {
          "data" => {"Get" => {"Question" => nil}},
          "errors" => [{"message" => "Cannot query field \"foo\" on type \"Question\"."}]
        })
      }

      it "raises a GraphQLError" do
        expect {
          query.get(class_name: "Question", fields: "foo")
        }.to raise_error(Weaviate::GraphQLError, "Cannot query field \"foo\" on type \"Question\".") { |e|
          expect(e).to be_a(Weaviate::Error)
          expect(e.errors.first["message"]).to include("Cannot query field")
        }
      end
    end
  end

  describe "#aggs" do
    let(:response) {
      OpenStruct.new(body: {
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

    it "returns the query" do
      data = query.aggs(
        class_name: "Question",
        fields: "question, category",
        near_text: "{ concepts: [\"biology\"] }"
      )

      expect(data.count).to eq(1)
      expect(data.first["category"]).to eq("SCIENCE")
      expect(data.first["question"]).to eq("In 1953 Watson & Crick built a model of the molecular structure of this, the gene-carrying substance")
      expect(squish(@captured_query)).to eq(
        '{ Aggregate { Question(nearText: { concepts: ["biology"] }) { question, category } } }'
      )
    end

    it "passes group_by and object_limit" do
      query.aggs(
        class_name: "Question",
        fields: "meta { count }",
        group_by: ["category"],
        object_limit: "10"
      )

      expect(squish(@captured_query)).to eq(
        '{ Aggregate { Question(objectLimit: 10, groupBy: ["category"]) { meta { count } } } }'
      )
    end
  end

  describe "#aggs limit and hybrid" do
    let(:response) { OpenStruct.new(body: {"data" => {"Aggregate" => {"Question" => []}}}) }

    it "passes limit and hybrid" do
      query.aggs(class_name: "Question", fields: "meta { count }", with_hybrid: {query: "biology", alpha: 0.5}, object_limit: 10, limit: 5)

      expect(squish(@captured_query)).to eq(
        '{ Aggregate { Question(objectLimit: 10, limit: 5, hybrid: { query: "biology", alpha: 0.5 }) { meta { count } } } }'
      )
    end
  end

  describe "#explore" do
    let(:response) {
      OpenStruct.new(body: {
        "data" => {
          "Explore" => [{"certainty" => "0.9999", "class_name" => "Question"}]
        }
      })
    }

    before { allow(query).to receive(:warn) }

    it "warns that it is deprecated, once" do
      expect(query).to receive(:warn).with(/query.explore is deprecated/).once

      2.times { query.explore(fields: "className", near_vector: "{ vector: [0.1] }") }
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
      expect(squish(@captured_query)).to eq(
        '{ Explore(limit: 1, nearText: { concepts: ["biology"] }) { certainty className } }'
      )
    end

    it "ignores after, which Explore does not support" do
      query.explore(fields: "className", near_vector: "{ vector: [0.1] }", after: "abc")

      expect(squish(@captured_query)).to eq("{ Explore(nearVector: { vector: [0.1] }) { className } }")
    end
  end
end
