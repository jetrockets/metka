# frozen_string_literal: true

require "test_helper"

class TaggedWithAnyTest < ActiveSupport::TestCase
  test "returns collection where any of the specified tags appear" do
    assert_equal 2, Post.tagged_with("elixir, rails, ruby", any: true).size
  end

  test "returns collection where any of the specified tags appear in both tag columns" do
    assert_equal 1, Post.tagged_with([ "ruby", "rails" ], join_operator: Metka::AND, any: true).size
    assert_equal 0, Post.tagged_with("php", join_operator: Metka::AND, any: true).size
  end
end
