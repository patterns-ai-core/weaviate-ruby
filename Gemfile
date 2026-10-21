# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in weaviate.gemspec
gemspec

gem "rake", "~> 13.0"

gem "rspec", "~> 3.0"

gem "ostruct" # used in specs, no longer a default gem on Ruby >= 3.5

# Linting runs on the latest Ruby only (standard requires Ruby >= 3.0). Skip with BUNDLE_WITHOUT=lint.
group :lint do
  gem "standard", "~> 1.57"
end
