# Weaviate

TODO: Delete this and the text below, and describe your gem

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/weaviate`. To experiment with that code, run `bin/console` for an interactive prompt.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add weaviate-ruby

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install weaviate-ruby

## Usage

### Instantiating the API client

```ruby
client = Weaviate::Client.new(
    scheme: 'https',
    host: 'some-endpoint.weaviate.network',  # Replace with your endpoint
    model_service: :openai, # Service that will be used to generate vector. Allowed values: :openai, :cohere, :huggingface
    model_service_api_key: ENV["MODEL_SERVICE_API_KEY"] # Either OpenAI, Co:here or Hugging Face API key
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
client.schema.list()

# Remove a class (and all data in the instances) from the schema.
client.schema.delete(class_name: 'Question')

# Update settings of an existing schema class.
client.schema.update(class_name: 'Question')

# Inspect the shards of a class
client.schema.shards()
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
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/andreibondarev/weaviate.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
