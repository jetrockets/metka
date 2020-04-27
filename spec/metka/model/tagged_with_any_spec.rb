# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metka::Model, :db do
  let(:user) { User.create(name: Faker::Name.name) }

  before do
    ViewPost.create(user_id: user.id, tags: ['ruby', 'elixir', 'crystal'], materials: ['ruby', 'wood'])
    ViewPost.create(user_id: user.id, tags: ['ruby', 'rails', 'react'], materials: ['wood', 'stone'])
    ViewPost.create(user_id: user.id, tags: ['php', 'yii2', 'angular'], materials: [])
  end

  describe '.tagged_with' do
    context 'with :any option turned ON' do
      context 'when use default join operator' do
        it 'returns collection where any of the specified tags appear' do
          expect(ViewPost.tagged_with('elixir, rails, ruby', any: true).size).to eq(2)
        end
      end

      context 'when use AND as join operator' do
        it 'returns collection where any of the specified tags appear in both tag columns' do
          expect(ViewPost.tagged_with(['ruby', 'rails'], join_operator: Metka::AND, any: true).size).to eq(1)
          expect(ViewPost.tagged_with('php', join_operator: Metka::AND, any: true).size).to eq(0)
        end
      end
    end
  end
end
