# frozen_string_literal: true

require "test_helper"

class TaggedWithAllTest < ActiveSupport::TestCase
  test "returns collection where all provided tags are present in any of the tags columns" do
    assert_equal 0, Post.tagged_with("elixir, rails, ruby").size
  end

  test "returns collection where all provided tags are present in every of the tags columns" do
    assert_equal 1, Post.tagged_with("ruby", join_operator: ::Metka::AND).size
    assert_equal 0, Post.tagged_with("php", join_operator: ::Metka::AND).size
  end
end
