source "https://rubygems.org"

# Specify your gem's dependencies in metka.gemspec
gemspec

local_gemfile = "#{File.dirname(__FILE__)}/Gemfile.local"

if File.exist?(local_gemfile)
  eval(File.read(local_gemfile)) # rubocop:disable Lint/Eval
else
  gem 'activerecord', '>= 5.2.4', '< 6.2'
end