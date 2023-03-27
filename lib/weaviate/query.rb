# frozen_string_literal: true

module Weaviate
  class Query < Base
    def get(
      class_name:,
      fields:,
      limit: nil,
      near_text: nil
    )
      params = {}
      params["nearText"] = near_text unless near_text.nil?
      params["limit"] = limit unless limit.nil?
      # TODO implement the rest of the API params

      response = client.graphql.execute(get_query(class_name, params, fields), near_text: near_text)
      response.data.get.send(class_name.downcase)
    end

    private

    def get_query(class_name, params, fields)
      client.graphql.parse do
        query do
          Get do
            public_send(class_name, params) do
              fields.map do |field|
                public_send(field)
              end
            end
          end
        end
      end
    end
  end
end
