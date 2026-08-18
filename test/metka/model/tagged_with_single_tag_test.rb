# frozen_string_literal: true

require "test_helper"

class TaggedWithSingleTagTest < ActiveSupport::TestCase
  test "returns collection where provided tag is present in any of the tags columns" do
    assert_equal 2, Post.tagged_with("ruby").size
  end
end
