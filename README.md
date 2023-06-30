# Weaviate

<p>
    <img alt='Weaviate logo' src='https://weaviate.io/img/site/weaviate-logo-light.png' height='50' />
    +&nbsp;&nbsp;
    <img alt='Ruby logo' src='https://user-images.githubusercontent.com/541665/230231593-43861278-4550-421d-a543-fd3553aac4f6.png' height='40' />
</p>

Ruby wrapper for the Weaviate.io API.

Part of the [Langchain.rb](https://github.com/andreibondarev/langchainrb) stack.

![Tests status](https://github.com/andreibondarev/weaviate-ruby/actions/workflows/ci.yml/badge.svg)
[![Gem Version](https://badge.fury.io/rb/weaviate-ruby.svg)](https://badge.fury.io/rb/weaviate-ruby)
[![Docs](http://img.shields.io/badge/yard-docs-blue.svg)](http://rubydoc.info/gems/weaviate-ruby)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/andreibondarev/weaviate-ruby/blob/main/LICENSE.txt)
[![](https://dcbadge.vercel.app/api/server/WDARp7J2n8?compact=true&style=flat)](https://discord.gg/WDARp7J2n8)

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
    model_service: :openai, # Service that will be used to generate vectors. Possible values: :openai, :azure_openai, :cohere, :huggingface, :google_palm
    model_service_api_key: 'xxxxxxx' # Either OpenAI, Azure OpenAI, Cohere, Hugging Face or Google PaLM api key
)
```

### Using the Schema endpoints

```ruby
# Creating a new data object class in the schema
client.schema.create(
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
    # Possible values: 'text2vec-cohere', 'text2vec-openai', 'text2vec-huggingface', 'text2vec-transformers', 'text2vec-contextionary', 'img2vec-neural', 'multi2vec-clip', 'ref2vec-centroid'
    vectorizer: "text2vec-openai"
)

# Get a single class from the schema
client.schema.get(class_name: 'Question')

# Get the schema
client.schema.list()

# Remove a class (and all data in the instances) from the schema.
client.schema.delete(class_name: 'Question')

# Update settings of an existing schema class.
# Does not support modifying existing properties.
client.schema.update(
    class_name: 'Question',
    description: 'Information from a Wheel of Fortune question'
)

# Adding a new property
client.schema.add_property(
    class_name: 'Question',
    property: {
        "dataType": ["boolean"],
        "name": "homepage"
    }
)

# Inspect the shards of a class
client.schema.shards(class_name: 'Question')
```

### Using the Objects endpoint
```ruby
# Create a new data object. 
client.objects.create(
    class_name: 'Question',
    properties: {
        answer: '42',
        question: 'What is the meaning of life?',
        category: 'philosophy'
    }
)

# Lists all data objects in reverse order of creation.
client.objects.list()

# Get a single data object.
client.objects.get(
    class_name: "Question",
    id: "uuid"
)

# Check if a data object exists.
client.objects.exists?(
    class_name: "Question",
    id: "uuid"
)

# Delete a single data object from Weaviate.
client.objects.delete(
    class_name: "Question",
    id: "uuid"
)

# Update a single data object based on its uuid.
client.objects.update(
    class_name: "Question",
    id: "uuid",
    properties: {
        question: "What does 6 times 7 equal to?",
        category: "math",
        answer: "42"
    }
)

# Batch create objects
client.objects.batch_create(objects: [
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

# Batch delete objects
client.objects.batch_delete(
    class_name: "Question",
    where: {
        valueString: "uuid",
        operator: "Equal",
        path: ["id"]
    }
)
```

### Querying

#### Get{}
```ruby
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
```

#### Explore{}
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
```

### Nodes
```ruby
client.nodes
```

### Health
```ruby
# Live determines whether the application is alive. It can be used for Kubernetes liveness probe.
client.live?
```

```ruby
# Live determines whether the application is ready to receive traffic. It can be used for Kubernetes readiness probe.
client.ready?
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/andreibondarev/weaviate.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
