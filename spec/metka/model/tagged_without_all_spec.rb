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
        expect(ViewPost.tagged_with('ruby', exclude: true).size).to eq(1)
        expect(ViewPost.tagged_with('stone', exclude: true).size).to eq(2)
      end

      it 'should return empty collection if params empty' do
        ['', nil, []].each do |tags|
          expect(ViewPost.tagged_with(tags, exclude: true)).to eq(ViewPost.none)
        end
      end

      it 'should return collection' do
        expect(ViewPost.tagged_with('ruby, crystal, wood', exclude: true).size).to eq(3)
      end
    end

    context 'when use AND as join operator' do
      it 'should return collection without tag ruby' do
        view_posts = ViewPost.tagged_with('ruby', exclude: true, join_operator: Metka::AND)

        expect(view_posts.size).to eq(2)
      end

      it 'should return collection without tag php' do
        view_posts = ViewPost.tagged_with('php', exclude: true, join_operator: Metka::AND)

        expect(view_posts.size).to eq(3)
      end

      it 'should return collection' do
        expect(ViewPost.tagged_with('ruby, crystal, wood', exclude: true, join_operator: Metka::AND).size).to eq(3)
      end
    end
  end
end
