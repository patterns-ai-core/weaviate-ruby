# frozen_string_literal: true

module Weaviate
  class Clusters < Base
    PATH = "clusters"

    # Create the cluster and return The Weaviate server URL.
    def create(
      modules:, cluster_name: nil,
      cluster_type: "sandbox",
      with_auth: false
    )
      response = client.wsc.post(PATH) do |req|
        req.body = {}
        req.body["id"] = cluster_name if cluster_name
        req.body["configuration"] = {
          tier: cluster_type,
          requiresAuthentication: with_auth,
          modules: modules
        }
      end
    end

    def get(
      cluster_name:
    )
      response = client.wsc.get("#{PATH}/#{cluster_name.downcase}")
      response.body
    end
  end
end
