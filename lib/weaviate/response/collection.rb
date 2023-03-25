# frozen_string_literal: true
require 'pry'
module Weaviate
  module Response
    class Collection
      attr_reader :data, :total_results

      def self.from_response(response, key: nil, type:)
        body = response.body
        new(
          data: (key.nil? ? body : body[key]).map { |attrs| type.new(attrs) },
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
