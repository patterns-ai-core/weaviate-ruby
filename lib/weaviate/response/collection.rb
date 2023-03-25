# frozen_string_literal: true

module Weaviate
  module Response
    class Collection
      attr_reader :data, :total_results

      def self.from_response(response, key:, type:)
        body = response.body
        new(
          data: body[key].map { |attrs| type.new(attrs) },
          total_results: body["totalResults"]
        )
      end

      def initialize(data:, total_results:)
        @data = data
        @total_results = total_results
      end
    end
  end
end
