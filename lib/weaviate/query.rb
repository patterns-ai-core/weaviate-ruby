# frozen_string_literal: true

module Weaviate
  class Query < Base
    def get(
      class_name:,
      fields:,
      after: nil,
      tenant: nil,
      limit: nil,
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
      response = client.graphql.execute(
        get_query(
          class_name: class_name,
          tenant: tenant,
          fields: fields,
          sort: sort,
          where: where,
          near_text: near_text,
          near_vector: near_vector,
          near_image: near_image,
          near_object: near_object,
          with_hybrid: with_hybrid,
          bm25: bm25,
          ask: ask
        ),
        after: after,
        limit: limit,
        offset: offset
      )
      response.original_hash.dig("data", "Get", class_name)
    rescue Graphlient::Errors::ExecutionError => error
      raise Weaviate::Error.new(error.response.data.get.errors.messages.to_h)
    end

    def aggs(
      class_name:,
      fields: nil,
      object_limit: nil,
      near_text: nil,
      near_vector: nil,
      near_image: nil,
      near_object: nil,
      group_by: nil
    )
      response = client.graphql.execute(
        aggs_query(
          class_name: class_name,
          fields: fields,
          near_text: near_text,
          near_vector: near_vector,
          near_image: near_image,
          near_object: near_object
        ),
        group_by: group_by,
        object_limit: object_limit
      )
      response.original_hash.dig("data", "Aggregate", class_name)
    rescue Graphlient::Errors::ExecutionError => error
      raise Weaviate::Error.new(error.response.data.aggregate.errors.messages.to_h)
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
      response = client.graphql.execute(
        explore_query(
          fields: fields,
          near_text: near_text,
          near_vector: near_vector,
          near_image: near_image,
          near_object: near_object
        ),
        after: after,
        limit: limit,
        offset: offset
      )
      response.original_hash.dig("data", "Explore")
    rescue Graphlient::Errors::ExecutionError => error
      raise Weaviate::Error.new(error.to_s)
    end

    private

    def explore_query(
      fields:,
      where: nil,
      near_text: nil,
      near_vector: nil,
      near_image: nil,
      near_object: nil,
      sort: nil
    )
      client.graphql.parse <<~GRAPHQL
        query(
          $limit: Int,
          $offset: Int
        ) {
          Explore (
            limit: $limit,
            offset: $offset,
            #{near_text.present? ? "nearText: #{near_text}" : ""},
            #{near_vector.present? ? "nearVector: #{near_vector}" : ""},
            #{near_image.present? ? "nearImage: #{near_image}" : ""},
            #{near_object.present? ? "nearObject: #{near_object}" : ""}
            #{where.present? ? "where: #{where}" : ""},
            #{sort.present? ? "sort: #{sort}" : ""}
          ) {
            #{fields}
          }
        }
      GRAPHQL
    end

    def get_query(
      class_name:,
      fields:, tenant: nil,
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
      client.graphql.parse <<~GRAPHQL
        query(
          $after: String,
          $limit: Int,
          $offset: Int,
        ) {
          Get {
            #{class_name}(
              after: $after,
              limit: $limit,
              offset: $offset,
              #{tenant.present? ? "tenant: #{tenant}" : ""}
              #{near_text.present? ? "nearText: #{near_text}" : ""},
              #{near_vector.present? ? "nearVector: #{near_vector}" : ""},
              #{near_image.present? ? "nearImage: #{near_image}" : ""},
              #{near_object.present? ? "nearObject: #{near_object}" : ""},
              #{with_hybrid.present? ? "hybrid: #{with_hybrid}" : ""},
              #{bm25.present? ? "bm25: #{bm25}" : ""},
              #{ask.present? ? "ask: #{ask}" : ""},
              #{where.present? ? "where: #{where}" : ""},
              #{sort.present? ? "sort: #{sort}" : ""}
            ) {
              #{fields}
            }
          }
        }
      GRAPHQL
    end

    def aggs_query(
      class_name:,
      fields:,
      near_text: nil,
      near_vector: nil,
      near_image: nil,
      near_object: nil
    )
      client.graphql.parse <<~GRAPHQL
        query(
          $group_by: [String],
          $object_limit: Int,
        ) {
          Aggregate {
            #{class_name}(
              objectLimit: $object_limit,
              groupBy: $group_by,
              #{near_text.present? ? "nearText: #{near_text}" : ""},
              #{near_vector.present? ? "nearVector: #{near_vector}" : ""},
              #{near_image.present? ? "nearImage: #{near_image}" : ""},
              #{near_object.present? ? "nearObject: #{near_object}" : ""}
            ) {
              #{fields}
            }
          }
        }
      GRAPHQL
    end
  end
end
