# frozen_string_literal: true

module Weaviate
  class Schema < Base
    PATH = "schema"

    # TESTED
    # Dumps the current Weaviate schema. The result contains an array of objects.
    def list
      response = client.connection.get(PATH)
      Response::Collection.from_response(response, key: "classes", type: Response::Class)
    end

    # TESTED
    # Get a single class from the schema
    def get(class_name:)
      response = client.connection.get("#{PATH}/#{class_name}")

      if status.success?
        Response::Class.new(response.body)
      end
    end

    # TESTED
    # Create a new data object class in the schema.
    def create(
      class_name:,
      description:,
      properties:,
      vector_index_type: nil,
      vector_index_config: nil,
      vectorizer: nil,
      module_config: nil,
      inverted_index_config: nil,
      replication_config: nil
    )
      response = client.connection.post(PATH) do |req|
        req.body = {}
        req.body["class"] = class_name unless class_name.nil?
        req.body["description"] = description unless description.nil?
        req.body["vectorIndexType"] = vector_index_type unless vector_index_type.nil?
        req.body["vectorIndexConfig"] = vector_index_config unless vector_index_config.nil?
        req.body["vectorizer"] = vectorizer unless vectorizer.nil?
        req.body["moduleConfig"] = module_config unless module_config.nil?
        req.body["properties"] = properties unless properties.nil?
        req.body["invertedIndexConfig"] = inverted_index_config unless inverted_index_config.nil?
        req.body["replicationConfig"] = replication_config unless replication_config.nil?
      end

      if response.success?
        Response::Class.new(response.body)
      else
        response.body
      end
    end

    # TESTED
    # Remove a class (and all data in the instances) from the schema.
    def delete(class_name:)
      response = client.connection.delete("#{PATH}/#{class_name}")
      response.status == 200 && response.body.empty?
    end

    # TESTED
    # Update settings of an existing schema class.
    def update(
      class_name:,
      description: nil,
      vector_index_type: nil,
      vector_index_config: nil,
      vectorizer: nil,
      module_config: nil,
      properties: nil,
      inverted_index_config: nil,
      replication_config: nil
    )
      response = client.connection.put("#{PATH}/#{class_name}") do |req|
        req.body = {}
        req.body["class"] = class_name unless class_name.nil?
        req.body["description"] = description unless description.nil?
        req.body["vectorIndexType"] = vector_index_type unless vector_index_type.nil?
        req.body["vectorIndexConfig"] = vector_index_config unless vector_index_config.nil?
        req.body["vectorizer"] = vectorizer unless vectorizer.nil?
        req.body["moduleConfig"] = module_config unless module_config.nil?
        req.body["properties"] = properties unless properties.nil?
        req.body["invertedIndexConfig"] = inverted_index_config unless inverted_index_config.nil?
        req.body["replicationConfig"] = replication_config unless replication_config.nil?
      end

      if response.success?
        Response::Class.new(response.body)
      else
        response.body
      end
    end

    # Inspect the shards of a class
    def shards(class_name:)
      client.connection.get("#{PATH}/#{class_name}/shards")
    end

    # Update shard status
    def update_shard_status(class_name:, shard_name:, status:)
      validate_status!(status)

      client.connection.put("#{PATH}/#{class_name}/shards/#{shard_name}") do |req|
        req.body = {}
        req.body["status"] = status
      end
    end

    private

    def validate_status!(status)
      unless %w[READONLY READY].include?(status.to_s.upcase)
        raise ArgumentError, 'status must be either "READONLY" or "READY"'
      end
    end
  end
end
