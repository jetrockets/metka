# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metka::Model, '.tagged_with', db: true do
  before do
    # first post
    Post.create(user_id: user.id, tags: ['ruby', 'elixir', 'crystal'], categories: ['ruby', 'programming'])
    # second post
    Post.create(user_id: user.id, tags: ['ruby', 'rails', 'react'], categories: ['programming', 'backend'])
  end

  let!(:user) { User.create(name: Faker::Name.name) }
  let!(:third_post) { Post.create(user_id: user.id, tags: ['php', 'yii2', 'angular'], categories: []) }

  context 'when use default join operator' do
    it 'returns collection without tag ruby' do
      posts = Post.tagged_with('ruby', exclude: true, any: true)

      expect(posts.size).to eq(1)
      expect(posts.first).to eq(third_post)
    end

    it 'returns collection without tag backend' do
      posts = Post.tagged_with('backend', exclude: true, any: true)

      expect(posts.size).to eq(2)
    end

    it 'returns a collection if params empty' do
      ['', nil, []].each do |tags|
        expect(Post.tagged_with(tags, exclude: true, any: true)).to eq(Post.all)
      end
    end

    it 'returns collection' do
      expect(Post.tagged_with('ruby, crystal, programming', exclude: true, any: true).size).to eq(1)
    end
  end

  context 'when use AND as join operator' do
    it 'returns collection without tag ruby' do
      posts = Post.tagged_with('ruby, programming, foo', exclude: true, any: true, join_operator: Metka::AND)

      expect(posts.size).to eq(1)
    end

    it 'returns collection without tag php' do
      posts = Post.tagged_with('php', exclude: true, any: true, join_operator: Metka::AND)

      expect(posts.size).to eq(3)
    end

    it 'returns collection' do
      expect(
        Post.tagged_with('ruby, crystal, programming', exclude: true, any: true, join_operator: Metka::AND).size
      ).to eq(1)
    end
  end
end
