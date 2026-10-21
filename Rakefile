# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "yard"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

YARD::Rake::YardocTask.new do |t|
  # Document from the Ruby sources only. YARD's RBS parser doesn't handle multi-line signatures in sig/
  t.files = ["lib/**/*.rb"]
  t.options = ["--fail-on-warning"]
end
