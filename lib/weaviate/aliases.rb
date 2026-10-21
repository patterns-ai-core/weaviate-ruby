# frozen_string_literal: true

module Weaviate
  # Aliases are alternative names for a collection, e.g. to switch a "Products" alias to a newly built collection.
  class Aliases < Base
    PATH = "aliases"

    def list(class_name: nil)
      response = client.connection.get(PATH) do |req|
        req.params["class"] = class_name unless class_name.nil?
      end
      response.body
    end

    def create(alias_name:, class_name:)
      response = client.connection.post(PATH) do |req|
        req.body = {alias: alias_name, class: class_name}
      end
      response.body
    end

    def get(alias_name:)
      response = client.connection.get("#{PATH}/#{alias_name}")
      response.body
    end

    # Point an alias to a different collection.
    def update(alias_name:, class_name:)
      response = client.connection.put("#{PATH}/#{alias_name}") do |req|
        req.body = {class: class_name}
      end
      response.body
    end

    def delete(alias_name:)
      response = client.connection.delete("#{PATH}/#{alias_name}")
      response.success?
    end
  end
end
