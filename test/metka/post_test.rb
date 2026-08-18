# frozen_string_literal: true

require "test_helper"

class PostTest < ActiveSupport::TestCase
  test "tagging clouds are correctly generated for tags column" do
    assert_equal [
      [ "angular", 1 ], [ "crystal", 1 ], [ "elixir", 1 ], [ "php", 1 ],
      [ "rails", 1 ], [ "react", 1 ], [ "ruby", 2 ], [ "yii2", 1 ]
    ], Post.tag_cloud.sort
  end

  test "tagging clouds are correctly generated for categories column" do
    assert_equal [ [ "backend", 1 ], [ "programming", 2 ], [ "ruby", 1 ] ], Post.category_cloud.sort
  end

  test "tagging clouds are correctly generated for both tags and categories columns" do
    assert_equal [
      [ "angular", 1 ], [ "backend", 1 ], [ "crystal", 1 ], [ "elixir", 1 ], [ "php", 1 ],
      [ "programming", 2 ], [ "rails", 1 ], [ "react", 1 ], [ "ruby", 3 ], [ "yii2", 1 ]
    ], Post.metka_cloud(:tags, :categories).sort
  end

  # "ruby" is tagged on two posts and categorised on one, so a cloud spanning
  # both columns has to sum it to three rather than report it twice.
  test "sums a tag that appears in more than one taggable column" do
    assert_equal 2, Post.tag_cloud.to_h["ruby"]
    assert_equal 1, Post.category_cloud.to_h["ruby"]
    assert_equal 3, Post.metka_cloud(:tags, :categories).to_h["ruby"]
  end
end
