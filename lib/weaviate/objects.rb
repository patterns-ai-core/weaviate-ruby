# frozen_string_literal: true

module Weaviate
  class Objects < Base
    PATH = "objects"

    # Lists all data objects in reverse order of creation. The data will be returned as an array of objects.
    def list(
      class_name: nil,
      limit: nil,
      tenant: nil,
      offset: nil,
      after: nil,
      include: nil,
      sort: nil,
      order: nil
    )
      response = client.connection.get(PATH) do |req|
        req.params["class"] = class_name unless class_name.nil?
        req.params["tenant"] = tenant unless tenant.nil?
        req.params["limit"] = limit unless limit.nil?
        req.params["offset"] = offset unless offset.nil?
        req.params["after"] = after unless after.nil?
        req.params["include"] = include unless include.nil?
        req.params["sort"] = sort unless sort.nil?
        req.params["order"] = order unless order.nil?
      end

      response.body
    end

    # Create a new data object. The provided meta-data and schema values are validated.
    def create(
      class_name:,
      properties:,
      tenant: nil,
      consistency_level: nil,
      id: nil,
      vector: nil
    )
      validate_consistency_level!(consistency_level) unless consistency_level.nil?

      response = client.connection.post(PATH) do |req|
        unless consistency_level.nil?
          req.params = {
            consistency_level: consistency_level.to_s.upcase
          }
        end

        req.body = {}
        req.body["class"] = class_name
        req.body["properties"] = properties
        req.body["tenant"] = tenant unless tenant.blank?
        req.body["id"] = id unless id.nil?
        req.body["vector"] = vector unless vector.nil?
      end

      response.body
    end

    # Batch create objects
    def batch_create(
      objects:,
      consistency_level: nil
    )
      validate_consistency_level!(consistency_level) unless consistency_level.nil?

      response = client.connection.post("batch/#{PATH}") do |req|
        req.params["consistency_level"] = consistency_level.to_s.upcase unless consistency_level.nil?
        req.body = {objects: objects}
      end

      response.body
    end

    # Get a single data object.
    def get(
      class_name:,
      id:,
      include: nil,
      consistency_level: nil
    )
      validate_consistency_level!(consistency_level) unless consistency_level.nil?

      response = client.connection.get("#{PATH}/#{class_name}/#{id}") do |req|
        req.params["consistency_level"] = consistency_level.to_s.upcase unless consistency_level.nil?
        req.params["include"] = include unless include.nil?
      end

      response.body
    end

    # Check if a data object exists
    def exists?(
      class_name:,
      id:,
      consistency_level: nil
    )
      validate_consistency_level!(consistency_level) unless consistency_level.nil?

      response = client.connection.head("#{PATH}/#{class_name}/#{id}") do |req|
        req.params["consistency_level"] = consistency_level.to_s.upcase unless consistency_level.nil?
      end

      response.status == 204
    end

    # Update an individual data object based on its uuid.
    def update(
      class_name:,
      id:,
      properties:,
      vector: nil,
      consistency_level: nil
    )
      validate_consistency_level!(consistency_level) unless consistency_level.nil?

      response = client.connection.put("#{PATH}/#{class_name}/#{id}") do |req|
        req.params["consistency_level"] = consistency_level.to_s.upcase unless consistency_level.nil?

        req.body = {}
        req.body["id"] = id
        req.body["class"] = class_name
        req.body["properties"] = properties
        req.body["vector"] = vector unless vector.nil?
      end

      response.body
    end

    # Delete an individual data object from Weaviate.
    def delete(
      class_name:,
      id:,
      consistency_level: nil
    )
      validate_consistency_level!(consistency_level) unless consistency_level.nil?

      response = client.connection.delete("#{PATH}/#{class_name}/#{id}") do |req|
        req.params["consistency_level"] = consistency_level.to_s.upcase unless consistency_level.nil?
      end

      if response.success?
        response.body.empty?
      else
        response.body
      end
    end

    def batch_delete(
      class_name:,
      where:,
      consistency_level: nil,
      output: nil,
      dry_run: nil
    )
      path = "batch/#{PATH}"

      unless consistency_level.nil?
        validate_consistency_level!(consistency_level)

        path << "?consistency_level=#{consistency_level.to_s.upcase}"
      end

      response = client.connection.delete(path) do |req|
        req.body = {
          match: {
            class: class_name,
            where: where
          }
        }
        req.body["output"] = output unless output.nil?
        req.body["dryRun"] = dry_run unless dry_run.nil?
      end

      response.body
    end

    # Validate a data object
    def validate(
      class_name:,
      properties:,
      id: nil
    )
      response = client.connection.post("#{PATH}/validate") do |req|
        req.body = {}
        req.body["class"] = class_name
        req.body["properties"] = properties
        req.body["id"] = id unless id.nil?
      end

      if response.success?
        response.body.empty?
      else
        response.body
      end
    end

    private

    def validate_consistency_level!(consistency_level)
      unless %w[ONE QUORUM ALL].include?(consistency_level.to_s.upcase)
        raise ArgumentError, 'consistency_level must be either "ONE" or "QUORUM" OR "ALL"'
      end
    end
  end
end
