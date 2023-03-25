# frozen_string_literal: true

RSpec.describe Weaviate do
  it "has a version number" do
    expect(Weaviate::VERSION).not_to be nil
  end
end
