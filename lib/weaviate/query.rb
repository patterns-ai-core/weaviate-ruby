# frozen_string_literal: true

require "json"

module Weaviate
  class Query < Base
    # Fields whose values are GraphQL enums, so strings are sent unquoted, e.g. operator: "Equal"
    ENUM_KEYS = %w[operator order fusionType].freeze

    GRAPHQL_NAME = /\A[_A-Za-z][_0-9A-Za-z]*\z/

    def get(
      class_name:,
      fields:,
      after: nil,
      tenant: nil,
      limit: nil,
      autocut: nil,
      offset: nil,
      sort: nil,
      where: nil,
      near_text: nil,
      near_vector: nil,
      near_image: nil,
      near_object: nil,
      with_hybrid: nil,
      bm25: nil,
      ask: nil
    )
      data = client.graphql.execute(
        get_query(
          class_name: class_name,
          fields: fields,
          after: after,
          tenant: tenant,
          limit: limit,
          autocut: autocut,
          offset: offset,
          sort: sort,
          where: where,
          near_text: near_text,
          near_vector: near_vector,
          near_image: near_image,
          near_object: near_object,
          with_hybrid: with_hybrid,
          bm25: bm25,
          ask: ask
        )
      )
      data.dig("Get", class_name)
    end

    def aggs(
      class_name:,
      fields: nil,
      tenant: nil,
      where: nil,
      object_limit: nil,
      near_text: nil,
      near_vector: nil,
      near_image: nil,
      near_object: nil,
      group_by: nil
    )
      data = client.graphql.execute(
        aggs_query(
          class_name: class_name,
          fields: fields,
          tenant: tenant,
          where: where,
          object_limit: object_limit,
          near_text: near_text,
          near_vector: near_vector,
          near_image: near_image,
          near_object: near_object,
          group_by: group_by
        )
      )
      data.dig("Aggregate", class_name)
    end

    def explore(
      fields:,
      after: nil,
      limit: nil,
      offset: nil,
      sort: nil,
      where: nil,
      near_text: nil,
      near_vector: nil,
      near_image: nil,
      near_object: nil
    )
      # `after` is accepted for backwards compatibility, but Explore does not support it
      data = client.graphql.execute(
        explore_query(
          fields: fields,
          limit: limit,
          offset: offset,
          sort: sort,
          where: where,
          near_text: near_text,
          near_vector: near_vector,
          near_image: near_image,
          near_object: near_object
        )
      )
      data["Explore"]
    end

    private

    def explore_query(
      fields:,
      limit: nil,
      offset: nil,
      where: nil,
      near_text: nil,
      near_vector: nil,
      near_image: nil,
      near_object: nil,
      sort: nil
    )
      arguments = build_arguments(
        limit: integer_value(limit),
        offset: integer_value(offset),
        nearText: near_text,
        nearVector: near_vector,
        nearImage: near_image,
        nearObject: near_object,
        where: where,
        sort: sort
      )

      <<~GRAPHQL
        {
          Explore#{arguments} {
            #{fields}
          }
        }
      GRAPHQL
    end

    def get_query(
      class_name:,
      fields:,
      after: nil,
      tenant: nil,
      limit: nil,
      autocut: nil,
      offset: nil,
      where: nil,
      near_text: nil,
      near_vector: nil,
      near_image: nil,
      near_object: nil,
      with_hybrid: nil,
      bm25: nil,
      ask: nil,
      sort: nil
    )
      arguments = build_arguments(
        after: string_value(after),
        limit: integer_value(limit),
        offset: integer_value(offset),
        autocut: integer_value(autocut),
        tenant: string_value(tenant),
        nearText: near_text,
        nearVector: near_vector,
        nearImage: near_image,
        nearObject: near_object,
        hybrid: with_hybrid,
        bm25: bm25,
        ask: ask,
        where: where,
        sort: sort
      )

      <<~GRAPHQL
        {
          Get {
            #{class_name}#{arguments} {
              #{fields}
            }
          }
        }
      GRAPHQL
    end

    def aggs_query(
      class_name:,
      fields:,
      tenant: nil,
      where: nil,
      object_limit: nil,
      near_text: nil,
      near_vector: nil,
      near_image: nil,
      near_object: nil,
      group_by: nil
    )
      arguments = build_arguments(
        objectLimit: integer_value(object_limit),
        groupBy: group_by && Array(group_by).map(&:to_s).to_json,
        tenant: string_value(tenant),
        nearText: near_text,
        nearVector: near_vector,
        nearImage: near_image,
        nearObject: near_object,
        where: where
      )

      <<~GRAPHQL
        {
          Aggregate {
            #{class_name}#{arguments} {
              #{fields}
            }
          }
        }
      GRAPHQL
    end

    # Only arguments that were provided are included in the query.
    # Weaviate fails on explicit nulls, e.g. "interface conversion: interface {} is nil, not int".
    # String arguments are passed through as raw GraphQL, anything else is serialized with {#graphql_value}.
    def build_arguments(**arguments)
      arguments = arguments.reject { |_, value| value.nil? }
      return "" if arguments.empty?

      arguments = arguments.map do |name, value|
        "#{name}: #{value.is_a?(String) ? value : graphql_value(value)}"
      end

      "(#{arguments.join(", ")})"
    end

    # Serializes a Ruby value into a GraphQL input value:
    #   { path: ["category"], operator: :Equal, valueText: "SCIENCE" }
    #   => { path: ["category"], operator: Equal, valueText: "SCIENCE" }
    # Strings are quoted and escaped, symbols become enums.
    def graphql_value(value, key = nil)
      case value
      when Hash
        "{ #{value.map { |k, v| "#{graphql_name(k)}: #{graphql_value(v, k.to_s)}" }.join(", ")} }"
      when Array
        "[#{value.map { |v| graphql_value(v, key) }.join(", ")}]"
      when Symbol
        graphql_name(value)
      when String
        (ENUM_KEYS.include?(key) && value.match?(GRAPHQL_NAME)) ? value : value.to_json
      when Numeric, true, false
        value.to_s
      when nil
        "null"
      else
        raise ArgumentError, "Cannot convert #{value.class} to a GraphQL value"
      end
    end

    def graphql_name(name)
      name = name.to_s
      raise ArgumentError, "Invalid GraphQL name: #{name.inspect}" unless name.match?(GRAPHQL_NAME)
      name
    end

    def integer_value(value)
      Integer(value) unless value.nil?
    end

    def string_value(value)
      value.to_s.to_json unless value.nil?
    end
  end
end
