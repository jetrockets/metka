# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require "bundler/setup"

require File.expand_path("dummy/config/environment", __dir__)

require "active_support/test_case"

require "timecop"
require "metka"

require "minitest/autorun"

class ActiveSupport::TestCase
  # Every test runs inside a transaction that is rolled back afterwards, so
  # the records built by one test are never visible to the next one.
  include ActiveRecord::TestFixtures

  self.fixture_paths = [ File.expand_path("fixtures", __dir__) ]
  self.use_transactional_tests = true

  fixtures :all
end
