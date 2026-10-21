# frozen_string_literal: true

module Weaviate
  class Backups < Base
    PATH = "backups"

    # List backups on a backend.
    # @param order [String] "asc" or "desc" (default) by start time
    def list(backend:, order: nil)
      response = client.connection.get("#{PATH}/#{backend}") do |req|
        req.params["order"] = order unless order.nil?
      end
      response.body
    end

    # @param config [Hash] Backup configuration, e.g. { Bucket: "my-bucket", Path: "backups", CPUPercentage: 80 }
    def create(
      backend:,
      id:,
      include: nil,
      exclude: nil,
      config: nil
    )
      response = client.connection.post("#{PATH}/#{backend}") do |req|
        req.body = {}
        req.body["id"] = id
        req.body["include"] = include if include
        req.body["exclude"] = exclude if exclude
        req.body["config"] = config if config
      end

      response.body
    end

    def get(
      backend:,
      id:,
      bucket: nil,
      path: nil
    )
      response = client.connection.get("#{PATH}/#{backend}/#{id}") do |req|
        location_params(req, bucket, path)
      end
      response.body
    end

    # Cancel a backup that is in progress.
    def cancel(
      backend:,
      id:,
      bucket: nil,
      path: nil
    )
      response = client.connection.delete("#{PATH}/#{backend}/#{id}") do |req|
        location_params(req, bucket, path)
      end
      response.success?
    end

    def restore(
      backend:,
      id:,
      include: nil,
      exclude: nil,
      config: nil
    )
      response = client.connection.post("#{PATH}/#{backend}/#{id}/restore") do |req|
        req.body = {}
        req.body["include"] = include if include
        req.body["exclude"] = exclude if exclude
        req.body["config"] = config if config
      end

      response.body
    end

    def restore_status(
      backend:,
      id:,
      bucket: nil,
      path: nil
    )
      response = client.connection.get("#{PATH}/#{backend}/#{id}/restore") do |req|
        location_params(req, bucket, path)
      end
      response.body
    end

    # Cancel a restore that is in progress.
    def cancel_restore(
      backend:,
      id:,
      bucket: nil,
      path: nil
    )
      response = client.connection.delete("#{PATH}/#{backend}/#{id}/restore") do |req|
        location_params(req, bucket, path)
      end
      response.success?
    end

    private

    def location_params(req, bucket, path)
      req.params["bucket"] = bucket unless bucket.nil?
      req.params["path"] = path unless path.nil?
    end
  end
end
