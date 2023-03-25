# frozen_string_literal: true

require "faraday"

module Weaviate
  class Client
    attr_reader :scheme, :host, :model_service, :model_service_api_key, :adapter

    API_VERSION = "v1"

    API_KEY_HEADERS = {
      openai: "X-OpenAI-Api-Key",
      cohere: "X-Cohere-Api-Key",
      huggingface: "X-HuggingFace-Api-Key"
    }

    def initialize(
      scheme:,
      host:,
      model_service: nil,
      model_service_api_key: nil,
      adapter: Faraday.default_adapter
    )
      validate_model_service!(model_service) unless model_service.nil?

      @scheme = scheme
      @host = host
      @model_service = model_service
      @model_service_api_key = model_service_api_key
      @adapter = adapter
    end

    def oidc
      Weaviate::OIDC.new(client: self).get
    end

    def schema
      @schema ||= Weaviate::Schema.new(client: self)
    end

    def meta
      @meta ||= Weaviate::Meta.new(client: self)
      @meta.get
    end

    def objects
      @objects ||= Weaviate::Objects.new(client: self)
    end

    def connection
      @connection ||= Faraday.new(url: "#{scheme}://#{host}/#{API_VERSION}/") do |faraday|
        faraday.request :json
        faraday.response :json, content_type: /\bjson$/
        faraday.adapter adapter

        faraday.headers[API_KEY_HEADERS[model_service]] = model_service_api_key if model_service && model_service_api_key
      end
    end

    private

    def validate_model_service!(model_service)
      unless API_KEY_HEADERS.key?(model_service)
        raise ArgumentError, "Invalid model service: #{model_service}. Acceptable values are: #{API_KEY_HEADERS.keys.join(", ")}"
      end
    end
  end
end
