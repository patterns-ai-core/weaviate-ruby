# frozen_string_literal: true

module Weaviate
  class Health < Base
    PATH = ".well-known"

    # Whether Weaviate is alive. Returns false when it responds with an error or cannot be reached.
    def live?
      check("#{PATH}/live")
    end

    # Whether Weaviate is ready to receive traffic. Returns false when it responds with an error
    # (e.g. 503 while starting up) or cannot be reached.
    def ready?
      check("#{PATH}/ready")
    end

    private

    def check(path)
      client.connection.get(path).status == 200
    rescue Weaviate::HTTPError, Weaviate::ConnectionFailed
      false
    end
  end
end
