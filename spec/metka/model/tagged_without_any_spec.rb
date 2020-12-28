# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metka::Model, :db do
  let!(:user) { User.create(name: Faker::Name.name) }

  let!(:first_post) {
    Post.create(user_id: user.id, tags: ['ruby', 'elixir', 'crystal'], categories: ['ruby', 'programming'])
  }

  let!(:second_post) {
    Post.create(user_id: user.id, tags: ['ruby', 'rails', 'react'], categories: ['programming', 'backend'])
  }

  let!(:third_post) { Post.create(user_id: user.id, tags: ['php', 'yii2', 'angular'], categories: []) }

  context 'when use default join operator' do
    it 'should return collection without tag ruby' do
      posts = Post.tagged_with('ruby', exclude: true, any: true)

      expect(posts.size).to eq(1)
      expect(posts.first).to eq(third_post)
    end

    it 'should return collection without tag backend' do
      posts = Post.tagged_with('backend', exclude: true, any: true)

      expect(posts.size).to eq(2)
    end

    it 'should return empty collection if params empty' do
      ['', nil, []].each do |tags|
        expect(Post.tagged_with(tags, exclude: true, any: true)).to eq(Post.none)
      end
    end

    it 'should return collection' do
      expect(Post.tagged_with('ruby, crystal, programming', exclude: true, any: true).size).to eq(1)
    end
  end

  context 'when use AND as join operator' do
    it 'should return collection without tag ruby' do
      posts = Post.tagged_with('ruby, programming, foo', exclude: true, any: true, join_operator: Metka::AND)

      expect(posts.size).to eq(1)
    end

    it 'should return collection without tag php' do
      posts = Post.tagged_with('php', exclude: true, any: true, join_operator: Metka::AND)

      expect(posts.size).to eq(3)
    end

    it 'should return collection' do
      expect(
        Post.tagged_with('ruby, crystal, programming', exclude: true, any: true, join_operator: Metka::AND).size
      ).to eq(1)
    end
  end
end
