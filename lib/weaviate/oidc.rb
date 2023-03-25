# frozen_string_literal: true

module Weaviate
  class OIDC < Base
    PATH = ".well-known/openid-configuration"

    def get
      response = client.connection.get(PATH)
      response.body
    end
  end
end
