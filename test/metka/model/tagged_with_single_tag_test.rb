# frozen_string_literal: true

require 'test_helper'

class TaggedWithSingleTagTest < ActiveSupport::TestCase
  setup do
    user = User.create(name: Faker::Name.name)

    Post.create(user_id: user.id, tags: ['ruby', 'elixir', 'crystal'], categories: ['ruby', 'programming'])
    Post.create(user_id: user.id, tags: ['ruby', 'rails', 'react'], categories: ['programming', 'backend'])
    Post.create(user_id: user.id, tags: ['php', 'yii2', 'angular'], categories: [])
  end

  test 'returns collection where provided tag is present in any of the tags columns' do
    assert_equal 2, Post.tagged_with('ruby').size
  end
end
