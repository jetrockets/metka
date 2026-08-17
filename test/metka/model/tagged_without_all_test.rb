# frozen_string_literal: true

require "test_helper"

class TaggedWithoutAllTest < ActiveSupport::TestCase
  setup do
    user = User.create(name: Faker::Name.name)

    Post.create(user_id: user.id, tags: [ "ruby", "elixir", "crystal" ], categories: [ "ruby", "programming" ])
    Post.create(user_id: user.id, tags: [ "ruby", "rails", "react" ], categories: [ "programming", "backend" ])
    Post.create(user_id: user.id, tags: [ "php", "yii2", "angular" ], categories: [])
  end

  test "returns collection where provided tag is not present in either tags column" do
    assert_equal 1, Post.tagged_with("ruby", exclude: true).size
    assert_equal 2, Post.tagged_with("backend", exclude: true).size
  end

  test "returns a collection if params empty" do
    [ "", nil, [] ].each do |tags|
      assert_equal Post.all.sort_by(&:id), Post.tagged_with(tags, exclude: true).sort_by(&:id)
    end
  end

  test "returns collection" do
    assert_equal 3, Post.tagged_with("ruby, crystal, programming", exclude: true).size
  end

  test "returns collection without tag ruby when use AND as join operator" do
    assert_equal 2, Post.tagged_with("ruby", exclude: true, join_operator: Metka::AND).size
  end

  test "returns collection without tag php when use AND as join operator" do
    assert_equal 3, Post.tagged_with("php", exclude: true, join_operator: Metka::AND).size
  end

  test "returns collection when use AND as join operator" do
    assert_equal 3, Post.tagged_with("ruby, crystal, programming", exclude: true, join_operator: Metka::AND).size
  end
end
