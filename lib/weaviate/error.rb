# frozen_string_literal: true

module Weaviate
  class Error < StandardError
  end

  # Raised when Weaviate cannot be reached
  class ConnectionFailed < Error
  end

  # Raised when a request times out
  class TimeoutError < ConnectionFailed
  end

  # Raised when Weaviate responds with a 4xx or 5xx status
  class HTTPError < Error
    attr_reader :response

    def initialize(message = nil, response: nil)
      @response = response
      super(message || "the server responded with status #{response&.status}")
    end

    def status
      response&.status
    end

    def body
      response&.body
    end
  end

  class ClientError < HTTPError; end

  class BadRequestError < ClientError; end

  class UnauthorizedError < ClientError; end

  class ForbiddenError < ClientError; end

  class ResourceNotFound < ClientError; end

  class ConflictError < ClientError; end

  class UnprocessableEntityError < ClientError; end

  class ServerError < HTTPError; end

  # Raised when a GraphQL query returns errors
  class GraphQLError < Error
    attr_reader :errors

    def initialize(errors)
      @errors = errors
      super(errors.map { |e| e["message"] }.join(", "))
    end
  end
end
