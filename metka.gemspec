# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "metka/version"

Gem::Specification.new do |spec|
  spec.name = "metka"
  spec.version = Metka::VERSION
  spec.authors = ["Igor Alexandrov"]
  spec.email = ["igor.alexandrov@gmail.com"]

  spec.summary = "Rails tagging system based on PostgreSQL arrays"
  spec.description = "Rails tagging system based on PostgreSQL arrays"
  spec.homepage = "https://github.com/jetrockets/metka"
  spec.license = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path("..", __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "dry-configurable"
  spec.add_dependency "rails", ">= 4.2"

  spec.add_development_dependency "ammeter"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "faker"
  spec.add_development_dependency "pg"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "standard"
  spec.add_development_dependency "timecop"
end
