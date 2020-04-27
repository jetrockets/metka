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
    context 'when use default join operator' do
      it 'returns collection where provided tag is not present in either tags column' do
        expect(ViewPost.tagged_without_all('ruby').size).to eq(1)
        expect(ViewPost.tagged_without_all('stone').size).to eq(2)
      end

      it 'should return full collection if params empty' do
        expect(ViewPost.tagged_without_all('').size).to eq(3)
        expect(ViewPost.tagged_without_all(nil).size).to eq(3)
        expect(ViewPost.tagged_without_all.size).to eq(3)
        expect(ViewPost.tagged_without_all([]).size).to eq(3)
      end

      it 'should return collection' do
        expect(ViewPost.tagged_without_all('ruby, crystal, wood').size).to eq(3)
      end
    end

    context 'when use AND as join operator' do
      it 'should return collection without tag ruby' do
        view_posts = ViewPost.tagged_without_all('ruby', join_operator: Metka::AND)

        expect(view_posts.size).to eq(2)
      end

      it 'should return collection without tag php' do
        view_posts = ViewPost.tagged_without_all('php', join_operator: Metka::AND)

        expect(view_posts.size).to eq(3)
      end

      it 'should return collection' do
        expect(ViewPost.tagged_without_all('ruby, crystal, wood', join_operator: Metka::AND).size).to eq(3)
      end
    end
  end
end
