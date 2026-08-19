# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'metka/version'

Gem::Specification.new do |spec|
  spec.name = 'metka'
  spec.version = Metka::VERSION
  spec.authors = [ 'Igor Aleksandrov' ]
  spec.email = [ 'igor.alexandrov@gmail.com' ]

  spec.summary = 'Rails tagging system based on PostgreSQL arrays and SQLite JSON columns'
  spec.description = 'Rails tagging system that stores tags in a PostgreSQL array column ' \
                     'or an SQLite JSON column — no join tables, no extra models, no N+1 queries.'
  spec.homepage = 'https://github.com/metka-ruby/metka'
  spec.license = 'MIT'

  spec.metadata = {
    'homepage_uri' => spec.homepage,
    'source_code_uri' => spec.homepage,
    'bug_tracker_uri' => "#{spec.homepage}/issues",
    'changelog_uri' => "#{spec.homepage}/releases",
    'rubygems_mfa_required' => 'true'
  }

  # Ship only the files needed at runtime: the library itself plus licensing
  # and top-level docs. Development files (tests, benchmarks, CI configs,
  # gemfiles, planning docs) stay out of the package.
  spec.files = Dir['lib/**/*'] + %w[LICENSE.txt README.md CODE_OF_CONDUCT.md]
  spec.require_paths = [ 'lib' ]

  spec.required_ruby_version = '>= 3.2'

  spec.add_dependency 'rails', '>= 7.1'

  spec.add_development_dependency 'minitest', '>= 5.15'
  spec.add_development_dependency 'pg', '>= 1.1'
  spec.add_development_dependency 'sqlite3', '>= 2.1'
  spec.add_development_dependency 'rake', '>= 0.8.7'
  spec.add_development_dependency 'rubocop-rails-omakase', '>= 1.1'
end
