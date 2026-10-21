# frozen_string_literal: true

require_relative "weaviate/version"
require_relative "weaviate/error"

module Weaviate
  autoload :Base, "weaviate/base"
  autoload :Client, "weaviate/client"
  autoload :Connection, "weaviate/connection"
  autoload :Collections, "weaviate/collections"
  autoload :Schema, "weaviate/collections"
  autoload :GraphQL, "weaviate/graphql"
  autoload :Meta, "weaviate/meta"
  autoload :Objects, "weaviate/objects"
  autoload :OIDC, "weaviate/oidc"
  autoload :Query, "weaviate/query"
  autoload :Nodes, "weaviate/nodes"
  autoload :Health, "weaviate/health"
  autoload :Classifications, "weaviate/classifications"
  autoload :Backups, "weaviate/backups"
  autoload :Aliases, "weaviate/aliases"
  autoload :Users, "weaviate/users"
  autoload :Roles, "weaviate/roles"
  autoload :Groups, "weaviate/groups"
end
