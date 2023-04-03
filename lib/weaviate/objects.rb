# frozen_string_literal: true

module Weaviate
  class Objects < Base
    PATH = "objects"

    # Lists all data objects in reverse order of creation. The data will be returned as an array of objects.
    def list(
      class_name: nil,
      limit: nil,
      offset: nil,
      after: nil,
      include: nil,
      sort: nil,
      order: nil
    )
      response = client.connection.get(PATH) do |req|
        req.params["class"] = class_name unless class_name.nil?
        req.params["limit"] = limit unless limit.nil?
        req.params["offset"] = offset unless offset.nil?
        req.params["after"] = after unless after.nil?
        req.params["include"] = include unless include.nil?
        req.params["sort"] = sort unless sort.nil?
        req.params["order"] = order unless order.nil?
      end
      Response::Collection.from_response(response.body, key: "objects", type: Response::Object)
    end

    # Create a new data object. The provided meta-data and schema values are validated.
    def create(
      class_name:,
      properties:,
      id: nil,
      vector: nil
    )
      response = client.connection.post(PATH) do |req|
        req.body = {}
        req.body["class"] = class_name
        req.body["properties"] = properties
        req.body["id"] = id unless id.nil?
        req.body["vector"] = vector unless vector.nil?
      end

      if response.success?
        Weaviate::Response::Object.new(response.body)
      else
        response.body
      end
    end

    # Batch create objects
    def batch_create(objects:)
      response = client.connection.post("batch/#{PATH}") do |req|
        req.body = {objects: objects}
      end

      if response.success?
        Response::Collection.from_response(response.body, type: Response::Object)
      end
    end

    # Get a single data object.
    def get(
      class_name:,
      id:,
      include: nil
    )
      # TODO: validate `include` param values
      # include	| query | param |	string |	Include additional information, such as classification info. Allowed values include: classification, vector.

      response = client.connection.get("#{PATH}/#{class_name}/#{id}") do |req|
        req.params["include"] = include unless include.nil?
      end

      if response.success?
        Weaviate::Response::Object.new(response.body)
      end
    end

    # Check if a data object exists
    def exists?(class_name:, id:)
      response = client.connection.head("#{PATH}/#{class_name}/#{id}")
      response.status == 204
    end

    # Update an individual data object based on its uuid.
    def update(
      class_name:,
      id:,
      properties:,
      vector: nil
    )
      response = client.connection.put("#{PATH}/#{class_name}/#{id}") do |req|
        req.body = {}
        req.body["id"] = id
        req.body["class"] = class_name
        req.body["properties"] = properties
        req.body["vector"] = vector unless vector.nil?
      end
      if response.success?
        Weaviate::Response::Object.new(response.body)
      end
    end

    # Delete an individual data object from Weaviate.
    def delete(class_name:, id:)
      response = client.connection.delete("#{PATH}/#{class_name}/#{id}")
      response.success? && response.body.empty?
    end

    # Validate a data object
    # def validate
    # end
  end
end
