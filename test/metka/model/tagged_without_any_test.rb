# frozen_string_literal: true

require "test_helper"

class TaggedWithoutAnyTest < ActiveSupport::TestCase
  setup do
    user = User.create(name: Faker::Name.name)

    # first post
    Post.create(user_id: user.id, tags: [ "ruby", "elixir", "crystal" ], categories: [ "ruby", "programming" ])
    # second post
    Post.create(user_id: user.id, tags: [ "ruby", "rails", "react" ], categories: [ "programming", "backend" ])

    @third_post = Post.create(user_id: user.id, tags: [ "php", "yii2", "angular" ], categories: [])
  end

  test "returns collection without tag ruby" do
    posts = Post.tagged_with("ruby", exclude: true, any: true)

    assert_equal 1, posts.size
    assert_equal @third_post, posts.first
  end

  test "returns collection without tag backend" do
    assert_equal 2, Post.tagged_with("backend", exclude: true, any: true).size
  end

  test "returns a collection if params empty" do
    [ "", nil, [] ].each do |tags|
      assert_equal Post.all.sort_by(&:id), Post.tagged_with(tags, exclude: true, any: true).sort_by(&:id)
    end
  end

  test "returns collection" do
    assert_equal 1, Post.tagged_with("ruby, crystal, programming", exclude: true, any: true).size
  end

  test "returns collection without tag ruby when use AND as join operator" do
    posts = Post.tagged_with("ruby, programming, foo", exclude: true, any: true, join_operator: Metka::AND)

    assert_equal 1, posts.size
  end

  test "returns collection without tag php when use AND as join operator" do
    posts = Post.tagged_with("php", exclude: true, any: true, join_operator: Metka::AND)

    assert_equal 3, posts.size
  end

  test "returns collection when use AND as join operator" do
    assert_equal 1,
      Post.tagged_with("ruby, crystal, programming", exclude: true, any: true, join_operator: Metka::AND).size
  end
end
