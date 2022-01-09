# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'metka/version'

Gem::Specification.new do |spec|
  spec.name = 'metka'
  spec.version = Metka::VERSION
  spec.authors = ['Igor Alexandrov', 'Andrey Morozov']
  spec.email = ['igor.alexandrov@gmail.com', 'andrey.morozov@jetrockets.ru']

  spec.summary = 'Rails tagging system based on PostgreSQL arrays'
  spec.description = 'Rails tagging system based on PostgreSQL arrays'
  spec.homepage = 'https://github.com/jetrockets/metka'
  spec.license = 'MIT'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'dry-configurable', '>= 0.8'
  spec.add_dependency 'rails', '>= 5.2'

  spec.add_development_dependency 'ammeter', '>= 1.1'
  spec.add_development_dependency 'pry', '>= 0.12.2'
  spec.add_development_dependency 'bundler', '>= 1.3'
  spec.add_development_dependency 'faker', '>= 2.8'
  spec.add_development_dependency 'pg', '>= 1.1'
  spec.add_development_dependency 'rake', '>= 0.8.7'
  spec.add_development_dependency 'rspec', '>= 3.9'
  spec.add_development_dependency 'rspec-rails', '>= 3.9'
  spec.add_development_dependency 'timecop', '>= 0.9'
  spec.add_development_dependency 'database_cleaner', '>= 1.7'
  spec.add_development_dependency 'jetrockets-standard', '>= 1.1'
  spec.required_ruby_version = '>= 2.5'
end
