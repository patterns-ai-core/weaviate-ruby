# Weaviate

Ruby wrapper for the Weaviate.io API

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add weaviate-ruby

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install weaviate-ruby

## Usage

### Instantiating the API client

```ruby
require 'weaviate'

client = Weaviate::Client.new(
    scheme: 'https',
    host: 'some-endpoint.weaviate.network',  # Replace with your endpoint
    model_service: :openai, # Service that will be used to generate vectors. Possible values: :openai, :cohere, :huggingface
    model_service_api_key: 'xxxxxxx' # Either OpenAI, Cohere or Hugging Face API key
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
        } ,{ 
            "dataType": ["text"],
            "description": "The answer",
            "name": "answer"
        }, {
            "dataType": ["text"],
            "description": "The category",
            "name": "category"
        }
    ]
)

# Get a single class from the schema
client.schema.get(class_name: 'Question')

# Dumps the current Weaviate schema. 
response = client.schema.list()
response.data

# Remove a class (and all data in the instances) from the schema.
client.schema.delete(class_name: 'Question')

# Update settings of an existing schema class.
client.schema.update(class_name: 'Question')

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
response = client.objects.list()
response.data

# Get a single data object.
client.objects.get(
    class_name: "Question",
    id: ''
)

# Check if a data object exists
client.objects.exists?(
    class_name: "Question",
    id: ''
)

# Delete an individual data object from Weaviate.
client.objects.delete(
    class_name: "Question",
    id: ""
)

# Update an individual data object based on its uuid.
client.objects.update(
    class_name: "Question",
    id: '',
    properties: {
        question: "What does 6 times 7 equal to?",
        category: "math",
        answer: "42"
    }
)

# Batch create objects
client.objects.batch_create(objects: [
    {
        class_name: "Question",
        properties: {
        answer: "42",
        question: "What is the meaning of life?",
        category: "philosophy"
        }
    }, {
        class_name: "Question",
        properties: {
        answer: "42",
        question: "What does 6 times 7 equal to?",
        category: "math"
        }
    }
])
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/andreibondarev/weaviate.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
