# frozen_string_literal: true

module Weaviate
  class Classifications < Base
    PATH = "classifications"

    def get(id:)
      response = client.connection.get("#{PATH}/#{id}")
      response.body
    end

    def create(
      class_name:,
      type:,
      classify_properties: nil,
      based_on_properties: nil,
      settings: nil,
      filters: nil
    )
      response = client.connection.post(PATH) do |req|
        req.body = {}
        req.body["class"] = class_name
        req.body["type"] = type
        req.body["classifyProperties"] = classify_properties if classify_properties
        req.body["basedOnProperties"] = based_on_properties if based_on_properties
        req.body["settings"] = settings if settings
        req.body["filters"] = filters if filters
      end

      if response.success?
        response.body
      end
    end
  end
end
