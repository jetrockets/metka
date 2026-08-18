# frozen_string_literal: true

require "test_helper"

class MetkaModelTest < ActiveSupport::TestCase
  TAG_LIST = "ruby, elixir, crystal"

  # Generating this surface is the macro's whole job, so pin it once here
  # rather than repeating an existence check beside every test that calls it.
  test "declares a scope quartet, list accessors and a cloud per column" do
    %w[tags categories].each do |column|
      assert_respond_to Post, :"with_all_#{column}"
      assert_respond_to Post, :"with_any_#{column}"
      assert_respond_to Post, :"without_all_#{column}"
      assert_respond_to Post, :"without_any_#{column}"
      assert_respond_to Post, :"#{column.singularize}_cloud"
      assert_respond_to Post.new, :"#{column.singularize}_list"
      assert_respond_to Post.new, :"#{column.singularize}_list="
    end

    assert_respond_to Post, :tagged_with
    assert_respond_to Post, :metka_cloud
  end

  # .with_all_tags, default parser

  test ".with_all_tags is able to find by tag" do
    assert_predicate Post.with_all_tags(TAG_LIST), :present?
    assert_predicate Post.with_all_tags(TAG_LIST.split(", ").first), :present?
    assert_predicate Post.with_all_tags(TAG_LIST.split(", ").last), :present?
    assert_equal posts(:ruby_post), Post.with_all_tags(TAG_LIST).first
  end

  test ".with_all_tags returns a not empty scope for empty tags" do
    refute_empty Post.with_all_tags("")
  end

  test ".with_all_tags returns an empty scope for unused tags" do
    assert_empty Post.with_all_tags([ TAG_LIST.split(", ").first, "PHP" ])
  end

  # .with_any_tags, default parser

  test ".with_any_tags is able to find by tag" do
    assert_equal 2, Post.with_any_tags(TAG_LIST + ", go").count
    assert_predicate Post.with_any_tags("go, elixir"), :present?
    assert_equal posts(:ruby_post), Post.with_any_tags("go, elixir").first
  end

  test ".with_any_tags returns an empty scope for unused tags" do
    assert_empty Post.with_any_tags("go")
  end

  # .without_all_tags

  test ".without_all_tags returns every post if tags empty" do
    [ "", nil, [] ].each do |tags|
      assert_equal Post.count, Post.without_all_tags(tags).size
    end
  end

  test ".without_all_tags returns the posts not carrying every given tag" do
    assert_equal [ posts(:ruby_post), posts(:rails_post) ].sort_by(&:id),
      Post.without_all_tags(posts(:php_post).tag_list.to_a).sort_by(&:id)
    assert_equal [ posts(:rails_post), posts(:php_post) ].sort_by(&:id),
      Post.without_all_tags(posts(:ruby_post).tag_list.to_a).sort_by(&:id)
  end

  test ".without_all_tags returns all post if posts dont include all tags" do
    assert_equal 3, Post.without_all_tags(posts(:php_post).tag_list.to_a << "123").count
  end

  # .without_any_tags

  test ".without_any_tags returns the posts carrying none of the given tags" do
    assert_equal 1, Post.without_any_tags([ "elixir", "php" ]).count
    assert_equal posts(:rails_post), Post.without_any_tags([ "elixir", "php" ]).first
  end

  # .tagged_with

  test ".tagged_with finds a post carrying all of the given tags" do
    posts(:ruby_post).update!(tags: posts(:ruby_post).tags + [ "php" ])

    assert_equal 1, Post.tagged_with(%w[php ruby]).count
    assert_equal posts(:ruby_post), Post.tagged_with(%w[php ruby]).first
  end

  test ".tagged_with any finds a post carrying at least one of the given tags" do
    assert_equal 1, Post.tagged_with(%w[php cobol], any: true).count
    assert_equal posts(:php_post), Post.tagged_with(%w[php cobol], any: true).first
  end

  test ".tagged_with exclude skips the posts carrying the given tags" do
    assert_equal 1, Post.tagged_with(%w[ruby], exclude: true).count
    assert_equal posts(:php_post), Post.tagged_with(%w[ruby], exclude: true).first
  end

  test ".tagged_with any: false requires all of the given tags" do
    posts(:ruby_post).update!(tags: posts(:ruby_post).tags + [ "php" ])

    assert_equal 1, Post.tagged_with(%w[php ruby], any: false).count
    assert_equal posts(:ruby_post), Post.tagged_with(%w[php ruby], any: false).first
  end

  test ".tagged_with only looks at the columns listed in :on" do
    assert_empty Post.tagged_with("php", on: [ "categories" ])
    assert_empty Post.tagged_with("elixir", on: [ "categories" ])
    assert_equal 1, Post.tagged_with("elixir", on: [ "tags" ]).count
    assert_equal posts(:ruby_post), Post.tagged_with("elixir", on: [ "tags" ]).first
  end

  test ".tagged_with returns the whole scope for empty tags" do
    [ "", nil, [] ].each do |tags|
      assert_equal Post.all.sort_by(&:id), Post.tagged_with(tags, any: false).sort_by(&:id)
      assert_equal Post.all.sort_by(&:id), Post.tagged_with(tags, any: true).sort_by(&:id)
      assert_equal Post.all.sort_by(&:id), Post.tagged_with(tags, exclude: true, any: true).sort_by(&:id)
      assert_equal Post.all.sort_by(&:id), Post.tagged_with(tags, exclude: true, any: false).sort_by(&:id)
    end
  end

  # Custom parser — User is tagged through CustomParser, which splits on "|"

  TAGS = "developer | senior"

  test ".with_all_tags is able to find by tags with a custom parser" do
    assert_predicate User.with_all_tags(TAGS), :present?
    assert_predicate User.with_all_tags(TAGS.split(" | ").first), :present?
    assert_equal users(:david), User.with_all_tags(TAGS).first
  end

  test ".with_all_tags returns a not empty scope for empty categories with a custom parser" do
    refute_empty User.with_all_tags("")
  end

  test ".with_all_tags returns an empty scope for unused categories with a custom parser" do
    assert_empty User.with_all_tags([ TAGS.split(" | ").first, "junior" ])
  end

  test ".with_any_tags is able to find by category with a custom parser" do
    new_tags_list = TAGS + " | backend"

    assert_predicate User.with_any_tags(new_tags_list), :present?
    assert_predicate User.with_any_tags(new_tags_list.split(" | ").first), :present?
    assert_equal users(:david), User.with_any_tags(new_tags_list).first
  end

  test ".with_any_tags returns an empty scope for unused tags with a custom parser" do
    assert_empty User.with_any_tags((TAGS + " | backend").split(" | ").last)
  end
end
