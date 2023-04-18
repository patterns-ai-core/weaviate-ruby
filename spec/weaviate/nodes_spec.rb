# frozen_string_literal: true

require "spec_helper"

RSpec.describe Weaviate::Nodes do
  let(:client) {
    Weaviate::Client.new(
      url: "http://localhost:8080"
    )
  }

  let(:nodes_fixture) { JSON.parse(File.read("spec/fixtures/nodes.json")) }

  describe "#list" do
    let(:response) {
      OpenStruct.new(body: nodes_fixture)
    }

    before do
      allow_any_instance_of(Faraday::Connection).to receive(:get)
        .with("nodes")
        .and_return(response)
    end

    it "return the nodes info" do
      expect(client.nodes).to be_a(Hash)
    end
  end
end
