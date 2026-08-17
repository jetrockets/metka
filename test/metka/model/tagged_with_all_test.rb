# frozen_string_literal: true

require 'test_helper'

class TaggedWithAllTest < ActiveSupport::TestCase
  setup do
    user = User.create(name: Faker::Name.name)

    Post.create(user_id: user.id, tags: ['ruby', 'elixir', 'crystal'], categories: ['ruby', 'programming'])
    Post.create(user_id: user.id, tags: ['ruby', 'rails', 'react'], categories: ['programming', 'backend'])
    Post.create(user_id: user.id, tags: ['php', 'yii2', 'angular'], categories: [])
  end

  test 'returns collection where all provided tags are present in any of the tags columns' do
    assert_equal 0, Post.tagged_with('elixir, rails, ruby').size
  end

  test 'returns collection where all provided tags are present in every of the tags columns' do
    assert_equal 1, Post.tagged_with('ruby', join_operator: ::Metka::AND).size
    assert_equal 0, Post.tagged_with('php', join_operator: ::Metka::AND).size
  end
end
