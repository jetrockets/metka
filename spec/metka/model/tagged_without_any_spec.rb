# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metka::Model, :db do
  let!(:user) { User.create(name: Faker::Name.name) }

  let!(:first_post) { ViewPost.create(user_id: user.id, tags: ['ruby', 'elixir', 'crystal'], materials: ['ruby', 'wood']) }
  let!(:second_post) { ViewPost.create(user_id: user.id, tags: ['ruby', 'rails', 'react'], materials: ['wood', 'stone']) }
  let!(:third_post) { ViewPost.create(user_id: user.id, tags: ['php', 'yii2', 'angular'], materials: []) }

  context 'when use default join operator' do
    it 'should return collection without tag ruby' do
      view_posts = ViewPost.tagged_with('ruby', exclude: true, any: true)

      expect(view_posts.size).to eq(1)
      expect(view_posts.first).to eq(third_post)
    end

    it 'should return collection without tag stone' do
      view_posts = ViewPost.tagged_with('stone', exclude: true, any: true)

      expect(view_posts.size).to eq(2)
    end

    it 'should return empty collection if params empty' do
      ['', nil, []].each do |tags|
        expect(ViewPost.tagged_with(tags, exclude: true, any: true)).to eq(ViewPost.none)
      end
    end

    it 'should return collection' do
      expect(ViewPost.tagged_with('ruby, crystal, wood', exclude: true, any: true).size).to eq(1)
    end
  end

  context 'when use AND as join operator' do
    it 'should return collection without tag ruby' do
      view_posts = ViewPost.tagged_with('ruby, wood, foo', exclude: true, any: true, join_operator: Metka::AND)

      expect(view_posts.size).to eq(1)
    end

    it 'should return collection without tag php' do
      view_posts = ViewPost.tagged_with('php', exclude: true, any: true, join_operator: Metka::AND)

      expect(view_posts.size).to eq(3)
    end

    it 'should return collection' do
      expect(ViewPost.tagged_with('ruby, crystal, wood', exclude: true, any: true, join_operator: Metka::AND).size).to eq(1)
    end
  end
end
