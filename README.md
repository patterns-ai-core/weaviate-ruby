# Weaviate

<p>
    <img alt='Weaviate logo' src='https://weaviate.io/img/site/weaviate-logo-light.png' height='50' />
    +&nbsp;&nbsp;
    <img alt='Ruby logo' src='https://user-images.githubusercontent.com/541665/230231593-43861278-4550-421d-a543-fd3553aac4f6.png' height='40' />
</p>

Ruby wrapper for the Weaviate.io API.

Part of the [Langchain.rb](https://github.com/patterns-ai-core/langchainrb) stack.

Available for paid consulting engagements! [Email me](mailto:andrei@sourcelabs.io).

![Tests status](https://github.com/patterns-ai-core/weaviate-ruby/actions/workflows/ci.yml/badge.svg)
[![Gem Version](https://badge.fury.io/rb/weaviate-ruby.svg)](https://badge.fury.io/rb/weaviate-ruby)
[![Docs](http://img.shields.io/badge/yard-docs-blue.svg)](http://rubydoc.info/gems/weaviate-ruby)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/patterns-ai-core/weaviate-ruby/blob/main/LICENSE.txt)
[![](https://dcbadge.vercel.app/api/server/WDARp7J2n8?compact=true&style=flat)](https://discord.gg/WDARp7J2n8)
[![X](https://img.shields.io/twitter/url/https/twitter.com/cloudposse.svg?style=social&label=Follow%20%40rushing_andrei)](https://twitter.com/rushing_andrei)

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add weaviate-ruby

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install weaviate-ruby

## Usage

### Instantiating API client

```ruby
require 'weaviate'

client = Weaviate::Client.new(
    url: 'https://some-endpoint.weaviate.network',  # Replace with your endpoint
    api_key: '', # Weaviate API key
    model_service: :openai, # Service used to generate vectors, see Weaviate::Client::API_KEY_HEADERS for all values (e.g. :openai, :cohere, :google_studio, :voyageai, :mistral)
    model_service_api_key: 'xxxxxxx', # API key for the model service
    headers: { 'X-Aws-Access-Key' => '...', 'X-Aws-Secret-Key' => '...' }, # Optional. Extra headers, e.g. for providers that need several keys or a custom base URL
    proxy: 'http://user:pass@localhost:8888', # Optional. Defaults to the http_proxy/https_proxy env vars
    open_timeout: 5, read_timeout: 30, write_timeout: 30, # Optional. In seconds, default to 60
    logger: Logger.new($stdout) # Optional. Requests and responses are logged with API keys filtered out
)
```

### Errors

All errors inherit from `Weaviate::Error`:

- `Weaviate::HTTPError` - Weaviate responded with a 4xx/5xx status (`#status` and `#body` are available). Subclasses: `Weaviate::BadRequestError`, `Weaviate::UnauthorizedError`, `Weaviate::ForbiddenError`, `Weaviate::ResourceNotFound`, `Weaviate::ConflictError`, `Weaviate::UnprocessableEntityError`, `Weaviate::ServerError`
- `Weaviate::GraphQLError` - a GraphQL query returned errors (`#errors` is available)
- `Weaviate::ConnectionFailed` / `Weaviate::TimeoutError` - Weaviate could not be reached

### Using the Collections endpoints

`client.collections` was previously called `client.schema`, which still works as an alias.

```ruby
# Creating a new collection
client.collections.create(
    class_name: 'Question',
    description: 'Information from a Jeopardy! question',
    properties: [
        {
            "dataType": ["text"],
            "description": "The question",
            "name": "question"
        }, { 
            "dataType": ["text"],
            "description": "The answer",
            "name": "answer"
        }, {
            "dataType": ["text"],
            "description": "The category",
            "name": "category"
        }
    ],
    # Possible values: 'text2vec-cohere', 'text2vec-ollama', 'text2vec-openai', 'text2vec-huggingface', 'text2vec-transformers', 'text2vec-contextionary', 'img2vec-neural', 'multi2vec-clip', 'ref2vec-centroid'
    vectorizer: "text2vec-openai"
)

# Get a single collection
client.collections.get(class_name: 'Question')

# List all collections
client.collections.list()

# Update settings of an existing collection.
# Does not support modifying existing properties.
client.collections.update(
    class_name: 'Question',
    description: 'Information from a Wheel of Fortune question'
)

# Adding a new property
client.collections.add_property(
    class_name: 'Question',
    property: {
        "dataType": ["boolean"],
        "name": "homepage"
    }
)

# Inspect the shards of a collection
client.collections.shards(class_name: 'Question')

# Remove a collection (and all data in the instances).
client.collections.delete(class_name: 'Question')

# Creating a new collection while configuring the vectorizer on the collection and on individual properties (Ollama example)
client.collections.create(
    class_name: 'Question',
    description: 'Information from a Jeopardy! question',
    properties: [
        {
            "dataType": ["text"],
            "description": "The question",
            "name": "question"
            # By default all properties are included in the vector
        }, { 
            "dataType": ["text"],
            "description": "The answer",
            "name": "answer",
            "moduleConfig": {
                "text2vec-ollama": {
                    "skip": false,
                    "vectorizePropertyName": true,
                },
            },
        }, {
            "dataType": ["text"],
            "description": "The category",
            "name": "category",
            "indexFilterable": true,
            "indexSearchable": false,
            "moduleConfig": {
                "text2vec-ollama": {
                    "skip": true, # Don't include in the vector
                },
            },
        }
    ],
    vectorizer: "text2vec-ollama",
    module_config: {
        "text2vec-ollama": {
            apiEndpoint: "http://localhost:11434",
            model: "mxbai-embed-large",
        },
    },
)

# Creating collections with named vectors

client.collections.create(
  class_name: 'ArticleNV',
  description: 'Articles with named vectors',
  properties: [
    {
      "dataType": ["text"],
      "name": "title"
    },
    {
      "dataType": ["text"],
      "name": "body"
    }
  ],
  # cannot use vectorizer and vector_config at the same time
  # will need to specify for each property
  vector_config: {
    "title": {
      "vectorizer": {
        "text2vec-openai": {
          "properties": ["title"]
        }
      },
      "vectorIndexType": "hnsw",  # This is the default 
    },
    "body": {
      "vectorizer": {
        "text2vec-openai": {
          "properties": ["body"]
        }
      },
      "vectorIndexType": "hnsw",  # This is the default

    }
  }
)
```

### Using the Objects endpoint
```ruby
# Create a new data object. 
output = client.objects.create(
    class_name: 'Question',
    properties: {
        answer: '42',
        question: 'What is the meaning of life?',
        category: 'philosophy'
    }
)
uuid = output["id"]

# Lists all data objects in reverse order of creation.
client.objects.list()

# Get a single data object.
client.objects.get(
    class_name: "Question",
    id: uuid
)

# Check if a data object exists.
client.objects.exists?(
    class_name: "Question",
    id: uuid
)

# Perform a partial update on an object based on its uuid.
client.objects.update(
    class_name: "Question",
    id: uuid,
    properties: {
        category: "simple-math"
    }
)

# Replace an object based on its uuid.
client.objects.replace(
    class_name: "Question",
    id: uuid,
    properties: {
        question: "What does 6 times 7 equal to?",
        category: "math",
        answer: "42"
    }
)

# Delete a single data object from Weaviate.
client.objects.delete(
    class_name: "Question",
    id: uuid
)

# Batch create objects
output = client.objects.batch_create(objects: [
    {
        class: "Question",
        properties: {
            answer: "42",
            question: "What is the meaning of life?",
            category: "philosophy"
        }
    }, {
        class: "Question",
        properties: {
            answer: "42",
            question: "What does 6 times 7 equal to?",
            category: "math"
        }
    }
])
uuids = output.pluck("id")

# Batch delete objects
client.objects.batch_delete(
    class_name: "Question",
    where: {
        valueStringArray: uuids,
        operator: "ContainsAny",
        path: ["id"]
    }
)

# References: add, replace and delete cross-references on a reference property
client.objects.add_reference(class_name: "Post", id: post_id, property: "ofCategory", to_class_name: "Category", to_id: category_id)
client.objects.replace_references(class_name: "Post", id: post_id, property: "ofCategory", to: [{ class_name: "Category", id: category_id }])
client.objects.delete_reference(class_name: "Post", id: post_id, property: "ofCategory", to_class_name: "Category", to_id: category_id)

# Batch create references
client.objects.batch_create_references(references: [
    { from_class_name: "Post", from_id: post_id, property: "ofCategory", to_class_name: "Category", to_id: category_id }
])
```

### Querying

#### Get{}

Arguments such as `where`, `near_text` or `sort` can be passed either as raw GraphQL strings or as Ruby hashes/arrays.
Hashes are converted to GraphQL: strings are quoted and escaped (safe for user input), and symbols are sent as enums.
`operator`, `order` and `fusionType` values are always sent as enums.

```ruby
client.query.get(
    class_name: 'Question',
    fields: 'question category',
    where: { path: ['category'], operator: :Equal, valueText: params[:category] },
    sort: [{ path: ['category'], order: :asc }],
    limit: 10
)

near_text = '{ concepts: ["biology"] }'
near_vector = '{ vector: [0.1, 0.2, ...] }'
sort_obj = '{ path: ["category"], order: desc }'
where_obj = '{ path: ["id"], operator: Equal, valueString: "..." }'
with_hybrid = '{ query: "Sweets", alpha: 0.5 }'

client.query.get(
    class_name: 'Question',
    fields: "question answer category _additional { answer { result hasAnswer property startPosition endPosition } }",
    limit: "1",
    offset: "1",
    after: "id",
    sort: sort_obj,
    where: where_obj,

    # To use this parameter you must have created your schema by setting the `vectorizer:` property to
    # either 'text2vec-transformers', 'text2vec-contextionary', 'text2vec-openai', 'multi2vec-clip', 'text2vec-huggingface' or 'text2vec-cohere'
    near_text: near_text,

    # To use this parameter you must have created your schema by setting the `vectorizer:` property to 'multi2vec-clip' or 'img2vec-neural'
    near_image: near_image,
    
    near_vector: near_vector,

    with_hybrid: with_hybrid,

    bm25: bm25,

    near_object: near_object,

    ask: '{ question: "your-question?" }'
)

# Example queries:
client.query.get class_name: 'Question', where: '{ operator: Like, valueText: "SCIENCE", path: ["category"] }', fields: 'answer question category', limit: "2"

client.query.get class_name: 'Question', fields: 'answer question category _additional { id }', after: "3c5f7039-37f3-4244-b3e2-8f4a083e448d", limit: "1"

# Limiting results by distance or certainty: pass `distance` or `certainty` along with `near_text`, `near_vector`
# or `near_object`, and request them back via `_additional`.
client.query.get(
    class_name: 'Question',
    fields: 'question _additional { distance certainty }',
    near_text: '{ concepts: ["biology"], distance: 0.6 }', # or certainty: 0.7
    limit: 5
)

# Grouping results by a property (requires a near_* or hybrid search)
client.query.get(
    class_name: 'Question',
    fields: '_additional { group { groupedBy { value } count hits { question _additional { id distance } } } }',
    near_text: { concepts: ['biology'] },
    group_by: { path: ['category'], groups: 3, objectsPerGroup: 2 }
)

# Named vector query - uses targetVectors
query_title = client.query.get(
  class_name: 'ArticleNV',
  fields: 'title body _additional { id }',
  near_text: '{
    targetVectors: ["title"],
    concepts: ["quantum computers advances"]
  }',
  limit: "2"
)



```

#### Aggs{}
```ruby
client.query.aggs(
    class_name: "Question",
    fields: 'meta { count }',
    group_by: ["category"],
    object_limit: "10",
    near_text: "{ concepts: [\"knowledge\"] }"
)

# Aggregating over hybrid search results, limiting the number of groups returned
client.query.aggs(
    class_name: "Question",
    fields: 'groupedBy { value } meta { count }',
    group_by: ["category"],
    with_hybrid: { query: "knowledge", alpha: 0.5 },
    object_limit: 100,
    limit: 5
)
```

#### Explore{}

**Deprecated.** Weaviate disables `Explore` when more than one vectorizer module is enabled, which is the case on a default install of recent versions and on Weaviate Cloud. Use `query.get` on each collection instead.

```ruby
client.query.explore(
    fields: 'className',
    near_text: "{ concepts: [\"science\"] }",
    limit: "1"
)
```

### Classification
```ruby
# Start a classification
client.classifications.create(
    type: "zeroshot",
    class_name: "Posts",
    classify_properties: ["hasColor"],
    based_on_properties: ["text"]
)

# Get the status, results and metadata of a previously created classification
client.classifications.get(
    id: ""
)
```

### Backups
```ruby
# Create backup
client.backups.create(
    backend: "filesystem",
    id: "my-first-backup",
    include: ["Question"]
)

# Get the backup
client.backups.get(
    backend: "filesystem",
    id: "my-first-backup"
)

# Restore backup
client.backups.restore(
    backend: "filesystem",
    id: "my-first-backup"
)

# Check the backup restore status
client.backups.restore_status(
    backend: "filesystem",
    id: "my-first-backup"
)

# List backups, newest first by default
client.backups.list(backend: "filesystem", order: "desc")

# Cancel a backup or restore that is in progress
client.backups.cancel(backend: "filesystem", id: "my-first-backup")
client.backups.cancel_restore(backend: "filesystem", id: "my-first-backup")

# Cloud storage backends accept a config, plus bucket/path when reading the status
client.backups.create(backend: "s3", id: "my-backup", config: { Bucket: "my-bucket", Path: "backups" })
client.backups.get(backend: "s3", id: "my-backup", bucket: "my-bucket", path: "backups")
```

### Nodes
```ruby
client.nodes

# Include shard details, optionally for one collection or shard
client.nodes(output: "verbose", class_name: "Question")
```

### Aliases
```ruby
# Point an alias at a collection, then query or write through the alias
client.aliases.create(alias_name: "Questions", class_name: "QuestionV1")
client.query.get(class_name: "Questions", fields: "question")

# Switch the alias to a new collection, e.g. after a re-index
client.aliases.update(alias_name: "Questions", class_name: "QuestionV2")

client.aliases.list
client.aliases.get(alias_name: "Questions")
client.aliases.delete(alias_name: "Questions")
```

### Users and roles

These require [RBAC](https://docs.weaviate.io/deploy/configuration/authorization) to be enabled.

```ruby
client.users.own_info

# Database users
response = client.users.create(user_id: "reporting")
response["apikey"] # The new user's API key
client.users.list
client.users.get(user_id: "reporting")
client.users.rotate_key(user_id: "reporting")
client.users.deactivate(user_id: "reporting", revoke_key: true)
client.users.activate(user_id: "reporting")
client.users.delete(user_id: "reporting")

# Roles and permissions
client.roles.create(
    name: "question-reader",
    permissions: [
        { action: "read_data", data: { collection: "Question" } },
        { action: "read_collections", collections: { collection: "*" } } # Required for GraphQL queries
    ]
)
client.roles.add_permissions(name: "question-reader", permissions: [{ action: "read_tenants", tenants: { collection: "Question" } }])
client.roles.has_permission?(name: "question-reader", permission: { action: "read_data", data: { collection: "Question" } })
client.roles.list

# Assigning roles to users (user_type: "db" or "oidc") and OIDC groups
client.users.assign_roles(user_id: "reporting", roles: ["question-reader"])
client.users.roles(user_id: "reporting")
client.roles.user_assignments(name: "question-reader")
client.users.revoke_roles(user_id: "reporting", roles: ["question-reader"])
client.groups.assign_roles(group_id: "analysts", roles: ["question-reader"])
```

### Health
```ruby
# Whether the application is alive. It can be used for Kubernetes liveness probe.
client.live?

# Whether the application is ready to receive traffic. It can be used for Kubernetes readiness probe.
# Both return false when Weaviate responds with an error or cannot be reached.
client.ready?
```

### Tenants

Any collection can be multi-tenant by passing in these options to `collections.create()`.

```ruby
client.collections.create(
    # Other keys...
    multi_tenant: true,
    auto_tenant_creation: true,
    auto_tenant_activation: true
)
```

See [Weaviate Multi-tenancy operations](https://weaviate.io/developers/weaviate/manage-data/multi-tenancy). Note that the mix of snake case(used by Ruby) and lower camel case(used by Weaviate) is intentional as that hash is passed directly to Weaviate.

All data methods in this library support an optional `tenant` argument which must be passed if multi-tenancy is enabled on the related collection.

```ruby
# Tenants can be added by name, or with an activity status
client.collections.add_tenants(class_name: "Question", tenants: ["tenant-a", { name: "tenant-b", activityStatus: "COLD" }])
client.collections.update_tenants(class_name: "Question", tenants: [{ name: "tenant-b", activityStatus: "HOT" }])
client.collections.get_tenant(class_name: "Question", tenant: "tenant-b")
client.collections.tenant_exists?(class_name: "Question", tenant: "tenant-b")
client.collections.list_tenants(class_name: "Question")
client.collections.remove_tenants(class_name: "Question", tenants: ["tenant-a"])
client.collections.shards(class_name: "Question", tenant: "tenant-b")
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/patterns-ai-core/weaviate-ruby.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
