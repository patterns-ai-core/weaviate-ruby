# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module Weaviate
  # A minimal HTTP client built on Net::HTTP
  class Connection
    Request = Struct.new(:params, :headers, :body)

    Response = Struct.new(:status, :reason_phrase, :headers, :body, keyword_init: true) do
      def success?
        (200..299).cover?(status)
      end
    end

    METHODS = {
      get: Net::HTTP::Get,
      head: Net::HTTP::Head,
      post: Net::HTTP::Post,
      put: Net::HTTP::Put,
      patch: Net::HTTP::Patch,
      delete: Net::HTTP::Delete
    }

    ERRORS = {
      400 => BadRequestError,
      401 => UnauthorizedError,
      403 => ForbiddenError,
      404 => ResourceNotFound,
      409 => ConflictError,
      422 => UnprocessableEntityError
    }

    FILTERED_HEADERS = /authorization|api-key|token|secret|access-key/i

    attr_reader :url, :headers, :logger, :proxy, :timeouts

    def initialize(url:, headers: {}, logger: nil, proxy: nil, open_timeout: nil, read_timeout: nil, write_timeout: nil)
      @url = url.chomp("/")
      @headers = headers
      @logger = logger
      @proxy = proxy && URI(proxy)
      @timeouts = {open_timeout: open_timeout, read_timeout: read_timeout, write_timeout: write_timeout}.compact
    end

    METHODS.each_key do |method|
      define_method(method) do |path, &block|
        request(method, path, &block)
      end
    end

    private

    def request(method, path)
      req = Request.new({}, {}, nil)
      yield req if block_given?

      uri = URI("#{url}/#{path}")
      uri.query = URI.encode_www_form(req.params) unless req.params.nil? || req.params.empty?

      http_request = METHODS.fetch(method).new(uri)
      headers.merge(req.headers).each { |k, v| http_request[k] = v }

      unless req.body.nil?
        http_request["Content-Type"] = "application/json"
        http_request.body = req.body.is_a?(String) ? req.body : req.body.to_json
      end

      log_request(http_request, uri)

      http_response = perform(uri, http_request)
      response = build_response(http_response)

      log_response(response, http_response)

      raise_error!(response) unless response.success?

      response
    end

    def perform(uri, http_request)
      Net::HTTP.start(
        uri.host,
        uri.port,
        proxy ? proxy.host : :ENV,
        proxy&.port,
        proxy&.user,
        proxy&.password,
        use_ssl: uri.scheme == "https",
        **timeouts
      ) do |http|
        http.request(http_request)
      end
    rescue Net::OpenTimeout, Net::ReadTimeout, Net::WriteTimeout => e
      raise Weaviate::TimeoutError, e.message
    rescue SocketError, SystemCallError, IOError, OpenSSL::SSL::SSLError => e
      raise Weaviate::ConnectionFailed, e.message
    end

    def build_response(http_response)
      body = http_response.body.to_s

      if http_response["Content-Type"].to_s.match?(/\bjson\b/) && !body.empty?
        body = JSON.parse(body)
      end

      Response.new(
        status: http_response.code.to_i,
        reason_phrase: http_response.message,
        headers: http_response.to_hash,
        body: body
      )
    end

    def raise_error!(response)
      error_class = ERRORS.fetch(response.status) do
        (response.status >= 500) ? ServerError : ClientError
      end

      raise error_class.new(response: response)
    end

    def log_request(http_request, uri)
      return if logger.nil?

      logger.info("request") { "#{http_request.method} #{uri}" }
      logger.info("request") { format_headers(http_request.each_header.to_h) }
      logger.info("request") { http_request.body } unless http_request.body.nil?
    end

    def log_response(response, http_response)
      return if logger.nil?

      logger.info("response") { "Status #{response.status}" }
      logger.info("response") { format_headers(http_response.each_header.to_h) }
      logger.info("response") { http_response.body } unless http_response.body.to_s.empty?
    end

    def format_headers(headers)
      headers.map do |k, v|
        "#{k}: #{k.match?(FILTERED_HEADERS) ? "[FILTERED]" : v.inspect}"
      end.join("\n")
    end
  end
end
