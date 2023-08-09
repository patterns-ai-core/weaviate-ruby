# frozen_string_literal: true

require "faraday"
require "graphlient"

module Weaviate
  class Client
    attr_reader :url, :api_key, :model_service, :model_service_api_key, :adapter

    API_VERSION = "v1"

    API_KEY_HEADERS = {
      openai: "X-OpenAI-Api-Key",
      azure_openai: "X-Azure-Api-Key",
      cohere: "X-Cohere-Api-Key",
      huggingface: "X-HuggingFace-Api-Key",
      google_palm: "X-Palm-Api-Key"
    }

    def initialize(
      url:,
      api_key: nil,
      model_service: nil,
      model_service_api_key: nil,
      adapter: Faraday.default_adapter
    )
      validate_model_service!(model_service) unless model_service.nil?

      @url = url
      @api_key = api_key
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

    def nodes
      @nodes ||= Weaviate::Nodes.new(client: self)
      @nodes.list
    end

    def live?
      @health ||= Weaviate::Health.new(client: self)
      @health.live?
    end

    def ready?
      @health ||= Weaviate::Health.new(client: self)
      @health.ready?
    end

    def backups
      @backups ||= Weaviate::Backups.new(client: self)
    end

    def classifications
      @classifications ||= Weaviate::Classifications.new(client: self)
    end

    def objects
      @objects ||= Weaviate::Objects.new(client: self)
    end

    def query
      @query ||= Weaviate::Query.new(client: self)
    end

    def graphql
      headers = {}

      if model_service && model_service_api_key
        headers[API_KEY_HEADERS[model_service]] = model_service_api_key
      end

      if api_key
        headers["Authorization"] = "Bearer #{api_key}"
      end

      @graphql ||= Graphlient::Client.new(
        "#{url}/#{API_VERSION}/graphql",
        headers: headers,
        http_options: {
          read_timeout: 20,
          write_timeout: 30
        }
      )
    end

    def connection
      @connection ||= Faraday.new(url: "#{url}/#{API_VERSION}/") do |faraday|
        if api_key
          faraday.request :authorization, :Bearer, api_key
        end
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
