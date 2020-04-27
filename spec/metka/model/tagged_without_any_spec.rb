# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metka::Model, :db do
  let!(:user) { User.create(name: Faker::Name.name) }

  let!(:first_post) { ViewPost.create(user_id: user.id, tags: ['ruby', 'elixir', 'crystal'], materials: ['ruby', 'wood']) }
  let!(:second_post) { ViewPost.create(user_id: user.id, tags: ['ruby', 'rails', 'react'], materials: ['wood', 'stone']) }
  let!(:third_post) { ViewPost.create(user_id: user.id, tags: ['php', 'yii2', 'angular'], materials: []) }

  it 'should respond to .tagged_without_any' do
    expect(ViewPost).to respond_to(:tagged_without_any)
  end

  context 'when use default join operator' do
    it 'should return collection without tag ruby' do
      view_posts = ViewPost.tagged_without_any('ruby')

      expect(view_posts.size).to eq(1)
      expect(view_posts.first).to eq(third_post)
    end

    it 'should return collection without tag stone' do
      view_posts = ViewPost.tagged_without_any('stone')

      expect(view_posts.size).to eq(2)
    end

    it 'should return full collection if params empty' do
      expect(ViewPost.tagged_without_any('').size).to eq(3)
      expect(ViewPost.tagged_without_any(nil).size).to eq(3)
      expect(ViewPost.tagged_without_any.size).to eq(3)
      expect(ViewPost.tagged_without_any([]).size).to eq(3)
    end

    it 'should return collection' do
      expect(ViewPost.tagged_without_any('ruby, crystal, wood').size).to eq(1)
    end
  end

  context 'when use AND as join operator' do
    it 'should return collection without tag ruby' do
      view_posts = ViewPost.tagged_without_any('ruby, wood, foo', join_operator: Metka::AND)

      expect(view_posts.size).to eq(1)
    end

    it 'should return collection without tag php' do
      view_posts = ViewPost.tagged_without_any('php', join_operator: Metka::AND)

      expect(view_posts.size).to eq(3)
    end

    it 'should return collection' do
      expect(ViewPost.tagged_without_any('ruby, crystal, wood', join_operator: Metka::AND).size).to eq(1)
    end
  end
end
