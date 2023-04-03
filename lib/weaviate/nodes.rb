# frozen_string_literal: true

module Weaviate
  class Nodes < Base
    PATH = "nodes"

    def list
      response = client.connection.get(PATH)
      response.body
    end
  end
end
