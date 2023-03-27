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

  module Response
    autoload :Base, "weaviate/response/base"
    autoload :Object, "weaviate/response/object"
    autoload :Class, "weaviate/response/class"
    autoload :Collection, "weaviate/response/collection"
  end
end
