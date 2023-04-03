# frozen_string_literal: true

module Weaviate
  class Health < Base
    PATH = ".well-known"

    def live?
      response = client.connection.get("#{PATH}/live")
      response.status == 200
    end

    def ready?
      response = client.connection.get("#{PATH}/ready")
      response.status == 200
    end
  end
end
