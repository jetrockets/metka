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
    context 'with :any option turned ON' do
      context 'when use default join operator' do
        it 'returns collection where any of the specified tags appear' do
          expect(Post.tagged_with('elixir, rails, ruby', any: true).size).to eq(2)
        end
      end

      context 'when use AND as join operator' do
        it 'returns collection where any of the specified tags appear in both tag columns' do
          expect(Post.tagged_with(['ruby', 'rails'], join_operator: Metka::AND, any: true).size).to eq(1)
          expect(Post.tagged_with('php', join_operator: Metka::AND, any: true).size).to eq(0)
        end
      end
    end
  end
end
