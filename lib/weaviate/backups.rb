# frozen_string_literal: true

module Weaviate
  class Backups < Base
    PATH = "backups"

    def create(
      backend:,
      id:,
      include: nil,
      exclude: nil
    )
      response = client.connection.post("#{PATH}/#{backend}") do |req|
        req.body = {}
        req.body["id"] = id
        req.body["include"] = include if include
        req.body["exclude"] = exclude if exclude
      end

      response.body
    end

    def get(
      backend:,
      id:
    )
      response = client.connection.get("#{PATH}/#{backend}/#{id}")
      response.body
    end

    def restore(
      backend:,
      id:,
      include: nil,
      exclude: nil
    )
      response = client.connection.post("#{PATH}/#{backend}/#{id}/restore") do |req|
        req.body = {}
        req.body["include"] = include if include
        req.body["exclude"] = exclude if exclude
      end

      response.body
    end

    def restore_status(
      backend:,
      id:
    )
      response = client.connection.get("#{PATH}/#{backend}/#{id}/restore")
      response.body
    end
  end
end
