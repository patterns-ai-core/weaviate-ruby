# frozen_string_literal: true

module Weaviate
  class GraphQL < Base
    PATH = "graphql"

    # Execute a GraphQL query and return the "data" portion of the response.
    def execute(query)
      response = client.connection.post(PATH) do |req|
        req.body = {query: query}
      end

      errors = response.body["errors"]
      raise Weaviate::GraphQLError.new(errors) if errors && !errors.empty?

      response.body["data"]
    end
  end
end
