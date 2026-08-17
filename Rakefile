# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.warning = false
  t.verbose = false
end

namespace :dummy do
  require_relative 'test/dummy/config/application'
  Dummy::Application.load_tasks
end

task default: :test
