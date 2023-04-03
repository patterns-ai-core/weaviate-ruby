# frozen_string_literal: true

require "spec_helper"

RSpec.describe Weaviate::Health do
  let(:client) {
    Weaviate::Client.new(
      scheme: "http",
      host: "localhost:8080"
    )
  }

  let(:response) {
    OpenStruct.new(status: 200)
  }

  describe "#live" do
    before do
      allow_any_instance_of(Faraday::Connection).to receive(:get)
        .with(".well-known/live")
        .and_return(response)
    end

    it "return 200" do
      expect(client.live?).to eq(true)
    end
  end

  describe "#ready" do
    before do
      allow_any_instance_of(Faraday::Connection).to receive(:get)
        .with(".well-known/ready")
        .and_return(response)
    end

    it "return 200" do
      expect(client.ready?).to eq(true)
    end
  end
end
