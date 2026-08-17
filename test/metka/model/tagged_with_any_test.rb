# frozen_string_literal: true

require 'test_helper'

class TaggedWithAnyTest < ActiveSupport::TestCase
  setup do
    user = User.create(name: Faker::Name.name)

    Post.create(user_id: user.id, tags: ['ruby', 'elixir', 'crystal'], categories: ['ruby', 'programming'])
    Post.create(user_id: user.id, tags: ['ruby', 'rails', 'react'], categories: ['programming', 'backend'])
    Post.create(user_id: user.id, tags: ['php', 'yii2', 'angular'], categories: [])
  end

  test 'returns collection where any of the specified tags appear' do
    assert_equal 2, Post.tagged_with('elixir, rails, ruby', any: true).size
  end

  test 'returns collection where any of the specified tags appear in both tag columns' do
    assert_equal 1, Post.tagged_with(['ruby', 'rails'], join_operator: Metka::AND, any: true).size
    assert_equal 0, Post.tagged_with('php', join_operator: Metka::AND, any: true).size
  end
end
