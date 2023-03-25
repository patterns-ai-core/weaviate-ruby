# frozen_string_literal: true

module Weaviate
  class Objects < Base
    PATH = "objects"

    # TESTED
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

      Response::Collection.from_response(response, key: "objects", type: Response::Object)
    end

    # TESTED
    # Create a new data object. The provided meta-data and schema values are validated.
    def create(
      class_name:,
      properties:,
      id: nil,
      vector: nil
    )
      client.connection.post(PATH) do |req|
        req.body = {}
        req.body["class"] = class_name
        req.body["properties"] = properties
        req.body["id"] = id unless id.nil?
        req.body["vector"] = vector unless vector.nil?
      end
    end

    def batch_create(objects:)
      client.connection.post("batch/#{PATH}") do |req|
        req.body = {objects: objects}
      end
    end

    # TESTED
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

      if status.success?
        Weaviate::Response::Object.new(response.body)
      end
    end

    # TESTED
    # Check if a data object exists
    def exists?(class_name:, id:)
      response = client.connection.head("#{PATH}/#{class_name}/#{id}")
      response.status == 204
    end

    # TESTED
    # Update an individual data object based on its uuid.
    def update(
      class_name:,
      id:,
      properties:,
      vector: nil
    )
      client.connection.put("#{PATH}/#{class_name}/#{id}") do |req|
        req.body = {}
        req.body["id"] = id
        req.body["class"] = class_name
        req.body["properties"] = properties
        req.body["vector"] = vector unless vector.nil?
      end
    end

    # TESTED
    # Delete an individual data object from Weaviate.
    def delete(class_name:, id:)
      response = client.connection.delete("#{PATH}/#{class_name}/#{id}")
      response.status == 200 && response.body.empty?
    end

    # Validate a data object
    # def validate
    # end
  end
end
