# frozen_string_literal: true

require_relative "weaviate/version"

module Weaviate
  autoload :Base, "weaviate/base"
  autoload :Client, "weaviate/client"
  autoload :Error, "weaviate/error"
  autoload :Schema, "weaviate/schema"
  autoload :Meta, "weaviate/meta"
  autoload :Objects, "weaviate/objects"
  autoload :OIDC, "weaviate/oidc"
  autoload :Query, "weaviate/query"
  autoload :Nodes, "weaviate/nodes"
  autoload :Health, "weaviate/health"
  autoload :Classifications, "weaviate/classifications"
  autoload :Backups, "weaviate/backups"
end
