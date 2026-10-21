# frozen_string_literal: true

require "logger"

module Weaviate
  class Client
    attr_reader :url, :api_key, :model_service, :model_service_api_key, :proxy, :logger

    API_VERSION = "v1"

    API_KEY_HEADERS = {
      ollama: "X-Ollama-Not-Used",
      openai: "X-OpenAI-Api-Key",
      azure_openai: "X-Azure-Api-Key",
      cohere: "X-Cohere-Api-Key",
      huggingface: "X-HuggingFace-Api-Key",
      google_palm: "X-Palm-Api-Key"
    }

    # @param url [String] The Weaviate instance URL
    # @param api_key [String] The Weaviate API key
    # @param model_service [Symbol] The service used to generate vectors, one of the API_KEY_HEADERS keys
    # @param model_service_api_key [String] The API key for the model service
    # @param proxy [String] Proxy URL, e.g. "http://user:pass@localhost:8888". Defaults to the http_proxy/https_proxy env vars.
    # @param logger [Logger] Logger for requests and responses
    # @param adapter [Object] Deprecated and ignored, Faraday is no longer used
    def initialize(
      url:,
      api_key: nil,
      model_service: nil,
      model_service_api_key: nil,
      proxy: nil,
      logger: nil,
      adapter: nil
    )
      validate_model_service!(model_service) unless model_service.nil?
      warn "[weaviate-ruby] The `adapter:` option is deprecated and ignored, Faraday is no longer used." unless adapter.nil?

      @url = url
      @api_key = api_key
      @model_service = model_service
      @model_service_api_key = model_service_api_key
      @proxy = proxy
      @logger = logger || Logger.new($stdout)
    end

    def oidc
      Weaviate::OIDC.new(client: self).get
    end

    def collections
      @collections ||= Weaviate::Collections.new(client: self)
    end

    # @deprecated Weaviate now refers to schema classes as collections. Use {#collections} instead.
    def schema
      collections
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
      @graphql ||= Weaviate::GraphQL.new(client: self)
    end

    def connection
      @connection ||= Weaviate::Connection.new(
        url: "#{url}/#{API_VERSION}",
        headers: headers,
        logger: logger,
        proxy: proxy
      )
    end

    private

    def headers
      headers = {}
      headers["Authorization"] = "Bearer #{api_key}" if api_key
      headers[API_KEY_HEADERS[model_service]] = model_service_api_key if model_service && model_service_api_key
      headers
    end

    def validate_model_service!(model_service)
      unless API_KEY_HEADERS.key?(model_service)
        raise ArgumentError, "Invalid model service: #{model_service}. Acceptable values are: #{API_KEY_HEADERS.keys.join(", ")}"
      end
    end
  end
end
