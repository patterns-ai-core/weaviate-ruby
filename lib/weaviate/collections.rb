# frozen_string_literal: true

module Weaviate
  # Manage collections (formerly known as "classes" in the Weaviate schema).
  class Collections < Base
    PATH = "schema"

    # Lists all collections in the Weaviate schema.
    def list
      response = client.connection.get(PATH)
      response.body
    end

    # Get a single collection
    def get(class_name:)
      response = client.connection.get("#{PATH}/#{class_name}")

      if response.success?
        response.body
      elsif response.status == 404
        response.reason_phrase
      end
    end

    # Create a new collection.
    def create(
      class_name:,
      description: nil,
      properties: nil,
      multi_tenant: false,
      auto_tenant_creation: false,
      auto_tenant_activation: false,
      vector_index_type: nil,
      vector_index_config: nil,
      vectorizer: nil,
      module_config: nil,
      inverted_index_config: nil,
      replication_config: nil,
      vector_config: nil
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

        if multi_tenant
          req.body["multiTenancyConfig"] = {
            enabled: multi_tenant,
            autoTenantCreation: auto_tenant_creation,
            autoTenantActivation: auto_tenant_activation
          }
        end

        req.body["invertedIndexConfig"] = inverted_index_config unless inverted_index_config.nil?
        req.body["replicationConfig"] = replication_config unless replication_config.nil?
        req.body["vectorConfig"] = vector_config unless vector_config.nil?
      end

      response.body
    end

    # Remove a collection (and all data in the instances).
    def delete(class_name:)
      response = client.connection.delete("#{PATH}/#{class_name}")

      if response.success?
        response.body.empty?
      else
        response.body
      end
    end

    # Update settings of an existing collection.
    # Weaviate replaces the whole collection definition on update, so the provided settings are merged
    # into the current definition. Immutable settings and existing properties cannot be changed.
    def update(
      class_name:,
      description: nil,
      vector_index_type: nil,
      vector_index_config: nil,
      vectorizer: nil,
      module_config: nil,
      properties: nil,
      inverted_index_config: nil,
      replication_config: nil,
      vector_config: nil
    )
      changes = {
        "description" => description,
        "vectorIndexType" => vector_index_type,
        "vectorIndexConfig" => vector_index_config,
        "vectorizer" => vectorizer,
        "moduleConfig" => module_config,
        "properties" => properties,
        "invertedIndexConfig" => inverted_index_config,
        "replicationConfig" => replication_config,
        "vectorConfig" => vector_config
      }.compact

      response = client.connection.put("#{PATH}/#{class_name}") do |req|
        req.body = deep_merge(get(class_name: class_name), JSON.parse(changes.to_json))
      end

      response.body
    end

    # Adds one or more tenants to a collection.
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

    # List tenants of a collection.
    def list_tenants(class_name:)
      response = client.connection.get("#{PATH}/#{class_name}/tenants")
      response.body
    end

    # Remove one or more tenants from a collection.
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

    # Add a property to an existing collection.
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

    # Inspect the shards of a collection
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

    def deep_merge(current, changes)
      current.merge(changes) do |_key, current_value, new_value|
        (current_value.is_a?(Hash) && new_value.is_a?(Hash)) ? deep_merge(current_value, new_value) : new_value
      end
    end

    def validate_status!(status)
      unless %w[READONLY READY].include?(status.to_s.upcase)
        raise ArgumentError, 'status must be either "READONLY" or "READY"'
      end
    end
  end

  # @deprecated Weaviate now refers to schema classes as collections. Use {Collections} instead.
  Schema = Collections
end
