# frozen_string_literal: true

require "ostruct"

module Weaviate
  module Response
    class Base < OpenStruct
      def initialize(attributes)
        super to_ostruct(attributes)
      end

      def to_ostruct(obj)
        if obj.is_a?(Hash)
          OpenStruct.new(obj.map { |key, val| [key, to_ostruct(val)] }.to_h)
        elsif obj.is_a?(Array)
          obj.map { |o| to_ostruct(o) }
        else # Assumed to be a primitive value
          obj
        end
      end  
    end
  end
end