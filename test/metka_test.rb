# frozen_string_literal: true

require 'test_helper'

class MetkaTest < ActiveSupport::TestCase
  test 'has a version number' do
    refute_nil Metka::VERSION
  end
end
