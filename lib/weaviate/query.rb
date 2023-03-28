# frozen_string_literal: true

module Weaviate
  class Query < Base
    # Meta-programming hack to dynamically create appropriate Weaviate GraphQL query. Expected query:
    #
    # Article(where: {
    #   ...
    #   operator: GreaterThan,  # operator
    #
    # Since `operator:` parameter expects a literal value, the only way to pass it in Ruby is by defining a class and returning it
    # inside of a lambda function when it's called. This is why we have the following code:
    # standard:disable all
    WHERE_OPERANDS = {
      and: -> { class ::And; end; And },
      or: -> { class ::Or; end; Or },
      equal: -> { class ::Equal; end; Equal },
      not_equal: -> { class ::NotEqual; end; NotEqual },
      greater_than: -> { class ::GreaterThan; end; GreaterThan },
      greater_than_equal: -> { class ::GreaterThanEqual; end; GreaterThanEqual },
      less_than: -> { class ::LessThan; end; LessThan },
      less_than_equal: -> { class ::LessThanEqual; end; LessThanEqual },
      like: -> { class ::Like; end; Like },
      within_geo_range: -> { class ::WithinGeoRange; end; WithinGeoRange },
      is_null: -> { class ::IsNull; end; IsNull }
    }.freeze
    # standard:enable all

    def get(
      class_name:,
      fields:,
      limit: nil,
      offset: nil,
      after: nil,
      sort: nil,
      where: nil,
      near_text: nil
    )
      params = {}
      params["nearText"] = near_text unless near_text.nil?
      params["limit"] = limit unless limit.nil?
      params["offset"] = offset unless offset.nil?
      params["after"] = after unless after.nil?

      if sort.present?
        # TODO: Implement the `order:` param
        # Unable to currently support the `order:` param. Weaviate GraphQL API expects a literal value, but we can't pass it in Ruby
        # Article(sort: [{
        #   order: asc # <--- this is the problem.
        # https://weaviate.io/developers/weaviate/api/graphql/filters#sorting-api
        #
        sort.delete("order")
        params["sort"] = sort
      end

      if where.present?
        params["where"] = where
        if where[:operator].present?
          params["where"][:operator] = WHERE_OPERANDS[where[:operator].to_sym].call
        end
        # TODO: Transform the multiple operands: [{}] case
      end

      # TODO implement the rest of the API params

      response = client.graphql.execute(get_query(class_name, params, fields), near_text: near_text)
      response.data.get.send(class_name.downcase)
    end

    private

    def get_query(class_name, params, fields)
      client.graphql.parse do
        query do
          Get do
            public_send(class_name, params) do
              fields.map do |field|
                public_send(field)
              end
            end
          end
        end
      end
    end
  end
end
