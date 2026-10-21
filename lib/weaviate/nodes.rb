# frozen_string_literal: true

module Weaviate
  class Nodes < Base
    PATH = "nodes"

    # @param output [String] "minimal" (default) or "verbose", which includes shard details
    # @param class_name [String] Only return shards of this collection
    # @param shard_name [String] Only return this shard, requires class_name
    def list(output: nil, class_name: nil, shard_name: nil)
      path = class_name.nil? ? PATH : "#{PATH}/#{class_name}"

      response = client.connection.get(path) do |req|
        req.params["output"] = output unless output.nil?
        req.params["shardName"] = shard_name unless shard_name.nil?
      end
      response.body
    end
  end
end
