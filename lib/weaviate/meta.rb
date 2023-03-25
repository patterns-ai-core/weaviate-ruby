# frozen_string_literal: true

module Weaviate
  class Meta < Base
    PATH = "meta"

    def get
      response = client.connection.get(PATH)
      response.body
    end
  end
end
