# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metka::Model, '.tagged_with', db: true do
  let(:user) { User.create(name: Faker::Name.name) }

  before do
    Post.create(user_id: user.id, tags: ['ruby', 'elixir', 'crystal'], categories: ['ruby', 'programming'])
    Post.create(user_id: user.id, tags: ['ruby', 'rails', 'react'], categories: ['programming', 'backend'])
    Post.create(user_id: user.id, tags: ['php', 'yii2', 'angular'], categories: [])
  end

  describe '.tagged_with' do
    it 'returns collection where provided tag is present in any of the tags columns' do
      expect(Post.tagged_with('ruby').size).to eq(2)
    end
  end
end
