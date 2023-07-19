# frozen_string_literal: true

module Weaviate
  class Schema < Base
    PATH = "schema"

    # Dumps the current Weaviate schema. The result contains an array of objects.
    def list
      response = client.connection.get(PATH)
      response.body
    end

    # Get a single class from the schema
    def get(class_name:)
      response = client.connection.get("#{PATH}/#{class_name}")

      if response.success?
        response.body
      elsif response.status == 404
        response.reason_phrase
      end
    end

    # Create a new data object class in the schema.
    def create(
      class_name:,
      description: nil,
      properties: nil,
      multi_tenant: nil,
      vector_index_type: nil,
      vector_index_config: nil,
      vectorizer: nil,
      module_config: nil,
      inverted_index_config: nil,
      replication_config: nil
    )
      response = client.connection.post(PATH) do |req|
        req.body = {}
        req.body["class"] = class_name
        req.body["description"] = description unless description.nil?
        req.body["vectorIndexType"] = vector_index_type unless vector_index_type.nil?
        req.body["vectorIndexConfig"] = vector_index_config unless vector_index_config.nil?
        req.body["vectorizer"] = vectorizer unless vectorizer.nil?
        req.body["moduleConfig"] = module_config unless module_config.nil?
        req.body["properties"] = properties unless properties.nil?
        req.body["multiTenancyConfig"] = {enabled: true} unless multi_tenant.nil?
        req.body["invertedIndexConfig"] = inverted_index_config unless inverted_index_config.nil?
        req.body["replicationConfig"] = replication_config unless replication_config.nil?
      end

      response.body
    end

    # Remove a class (and all data in the instances) from the schema.
    def delete(class_name:)
      response = client.connection.delete("#{PATH}/#{class_name}")

      if response.success?
        response.body.empty?
      else
        response.body
      end
    end

    # Update settings of an existing schema class.
    # TODO: Fix it.
    # This endpoint keeps returning the following error:
    # => {"error"=>[{"message"=>"properties cannot be updated through updating the class. Use the add property feature (e.g. \"POST /v1/schema/{className}/properties\") to add additional properties"}]}
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
      end
      response.body
    end

    # Adds one or more tenants to a class.
    def add_tenants(
      class_name:,
      tenants:
    )
      response = client.connection.post("#{PATH}/#{class_name}/tenants") do |req|
        tenants_str = tenants.map { |t| %({"name": "#{t}"}) }.join(", ")
        req.body = "[#{tenants_str}]"
      end
      response.body
    end

    # List tenants of a class.
    def list_tenants(class_name:)
      response = client.connection.get("#{PATH}/#{class_name}/tenants")
      response.body
    end

    # Remove one or more tenants from a class.
    def remove_tenants(
      class_name:,
      tenants:
    )
      response = client.connection.delete("#{PATH}/#{class_name}/tenants") do |req|
        req.body = tenants
      end

      if response.success?
      end

      response.body
    end

    # Add a property to an existing schema class.
    def add_property(
      class_name:,
      property:
    )
      response = client.connection.post("#{PATH}/#{class_name}/properties") do |req|
        req.body = property
      end

      if response.success?
      end
      response.body
    end

    # Inspect the shards of a class
    def shards(class_name:)
      response = client.connection.get("#{PATH}/#{class_name}/shards")
      response.body if response.success?
    end

    # Update shard status
    def update_shard_status(class_name:, shard_name:, status:)
      validate_status!(status)

      response = client.connection.put("#{PATH}/#{class_name}/shards/#{shard_name}") do |req|
        req.body = {}
        req.body["status"] = status
      end
      response.body if response.success?
    end

    private

    def validate_status!(status)
      unless %w[READONLY READY].include?(status.to_s.upcase)
        raise ArgumentError, 'status must be either "READONLY" or "READY"'
      end
    end
  end
end
