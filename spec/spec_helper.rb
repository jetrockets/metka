# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require "bundler/setup"
require "ammeter"
require "faker"
require "timecop"
require "metka"

require File.expand_path("dummy/config/environment", __dir__)

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.expose_dsl_globally = false

  config.example_status_persistence_file_path = "tmp/rspec_examples.txt"

  config.order = :random
  Kernel.srand config.seed

  config.before(:each, db: true) do
    ActiveRecord::Base.connection.begin_transaction(joinable: false)
  end

  config.append_after(:each, db: true) do
    ActiveRecord::Base.connection.rollback_transaction
  end
end
