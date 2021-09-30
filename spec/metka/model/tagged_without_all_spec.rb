# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metka::Model, :db do
  let(:user) { User.create(name: Faker::Name.name) }

  before do
    Post.create(user_id: user.id, tags: ['ruby', 'elixir', 'crystal'], categories: ['ruby', 'programming'])
    Post.create(user_id: user.id, tags: ['ruby', 'rails', 'react'], categories: ['programming', 'backend'])
    Post.create(user_id: user.id, tags: ['php', 'yii2', 'angular'], categories: [])
  end

  describe '.tagged_with' do
    context 'when use default join operator' do
      it 'returns collection where provided tag is not present in either tags column' do
        expect(Post.tagged_with('ruby', exclude: true).size).to eq(1)
        expect(Post.tagged_with('backend', exclude: true).size).to eq(2)
      end

      it 'returns a collection if params empty' do
        ['', nil, []].each do |tags|
          expect(Post.tagged_with(tags, exclude: true)).to eq(Post.all)
        end
      end

      it 'returns collection' do
        expect(Post.tagged_with('ruby, crystal, programming', exclude: true).size).to eq(3)
      end
    end

    context 'when use AND as join operator' do
      it 'returns collection without tag ruby' do
        posts = Post.tagged_with('ruby', exclude: true, join_operator: Metka::AND)

        expect(posts.size).to eq(2)
      end

      it 'returns collection without tag php' do
        posts = Post.tagged_with('php', exclude: true, join_operator: Metka::AND)

        expect(posts.size).to eq(3)
      end

      it 'returns collection' do
        expect(Post.tagged_with('ruby, crystal, programming', exclude: true, join_operator: Metka::AND).size).to eq(3)
      end
    end
  end
end
