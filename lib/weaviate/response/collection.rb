# frozen_string_literal: true

module Weaviate
  module Response
    class Collection
      attr_reader :data, :total_results

      def self.from_response(body, type:, key: nil)
        new(
          data: (key.nil? ? body : body[key]).map { |attrs| type.new(attrs) }
          # TODO: Integrate and use the totalResults from the response.
          # total_results: body["totalResults"]
        )
      end

      def initialize(data:, total_results: nil)
        @data = data
        @total_results = total_results
      end
    end
  end
end
