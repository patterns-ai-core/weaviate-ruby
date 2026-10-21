## [Unreleased]

## [0.10.0] - 2026-10-21
- Drop the `faraday` and `graphlient` dependencies in favor of Ruby's built-in `Net::HTTP` (#56)
- Fix `query.get` failing with "interface conversion: interface {} is nil, not int" on Weaviate >= 1.26.4. Only the arguments that are passed are sent in GraphQL queries (#63)
- Add `proxy:` option to `Weaviate::Client.new`. The `http_proxy`/`https_proxy` env vars are respected by default (#55)
- Add `client.collections` (`Weaviate::Collections`) to match Weaviate's terminology. `client.schema` and `Weaviate::Schema` remain as aliases (#69)
- API keys are filtered out of request logs
- Fix `collections.update` failing with 422 on immutable settings: the changes are now merged into the current collection definition, since Weaviate replaces the whole definition on update
- Fix `objects.exists?` raising on missing objects instead of returning `false`
- Fix `objects.batch_create(tenant:)` being ignored by Weaviate: the tenant is now set on each object
- Fix `query.aggs` failing with "groupBy must be a list, instead got: <nil>" when `group_by`/`object_limit` are not passed
- `live?`/`ready?` return `false` when Weaviate responds with an error (e.g. 503 while starting) or cannot be reached, instead of raising
- `collections.add_tenants` sends a JSON array and accepts hashes with `activityStatus`
- Query arguments (`where:`, `near_text:`, `sort:`, ...) can be Ruby hashes/arrays, serialized to GraphQL with strings escaped. Raw GraphQL strings still work
- Add API key headers for all model providers supported by Weaviate 1.38 (e.g. `:anthropic`, `:google_studio`, `:google_vertex`, `:mistral`, `:voyageai`, `:jinaai`, `:nvidia`)
- Add `headers:`, `open_timeout:`, `read_timeout:` and `write_timeout:` options to `Weaviate::Client.new`
- Add cross-references: `objects.add_reference`, `replace_references`, `delete_reference` and `batch_create_references`
- Add `group_by:` to `query.get`, and `limit:`/`with_hybrid:` to `query.aggs`
- Add `collections.update_tenants`, `get_tenant`, `tenant_exists?`, and `tenant:` to `collections.shards`
- Add `backups.list`, `cancel`, `cancel_restore`, `config:` on create/restore and `bucket:`/`path:` on status reads
- Add `client.nodes(output:, class_name:, shard_name:)`
- Add `client.aliases`, `client.users`, `client.roles` and `client.groups`
- Deprecate `query.explore`: Weaviate disables Explore when more than one vectorizer module is enabled
- Add RBS signatures for the public API
- Minimum Ruby version is now 2.7

### Breaking
- HTTP errors are raised as `Weaviate::HTTPError` subclasses (e.g. `Weaviate::ResourceNotFound`, `Weaviate::ServerError`) instead of `Faraday::Error` subclasses. Network failures raise `Weaviate::ConnectionFailed`/`Weaviate::TimeoutError`
- GraphQL errors are raised as `Weaviate::GraphQLError` (a `Weaviate::Error` subclass) whose message is the joined error messages
- `client.connection` returns a `Weaviate::Connection` and `client.graphql` returns a `Weaviate::GraphQL` instead of Faraday/Graphlient clients
- The `adapter:` option is deprecated and ignored

## [0.9.2] - 2024-10-01
- Weaviate::Client constructor accepts customer logger: to be passed in

## [0.9.1] - 2024-09-19

## [0.9.0] - 2024-07-08

- Add object.replace method which uses PUT which performs a complete object replacement

### Breaking
- Change the object.update method to use PATCH which only performs a partial update(previously performed a replacement)

## [0.8.11] - 2024-07-02
- Allow the user to specify any options they want for multi-tenancy when creating a schema using their own hash
- Allow Ollama vectorizer

## [0.8.10] - 2024-01-25

## [0.8.9] - 2023-10-10

## [0.8.8] - 2023-10-10

## [0.8.7] - 2023-09-11

## [0.8.6] - 2023-08-10

## [0.8.5] - 2023-07-19
- Add multi-tenancy support

## [0.8.4] - 2023-06-30
- Adding yard

## [0.8.3] - 2023-06-25
- Add Google PaLM support

## [0.8.2] - 2023-05-18

## [0.8.1] - 2023-05-10

## [0.8.0] - 2023-04-18

### Breaking
- Initializing the weaviate client requires the single `url:` key instead of separate `host:` and `schema:`

## [0.1.0] - 2023-03-24

- Initial release
