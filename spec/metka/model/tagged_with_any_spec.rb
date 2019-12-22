# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metka::Model, :db do
  let!(:user) { User.create(name: Faker::Name.name) }

  let!(:first_post)  { ViewPost.create(user_id: user.id, tags: ['ruby', 'elixir', 'crystal'], materials: ['ruby', 'wood'])}
  let!(:second_post) { ViewPost.create(user_id: user.id, tags: ['ruby', 'rails', 'react'], materials: ['wood', 'stone'])}
  let!(:third_post)  { ViewPost.create(user_id: user.id, tags: ['php', 'yii2', 'angular'], materials: [])}

  it "should respond to .tagged_with_any" do
    expect(ViewPost).to respond_to(:tagged_with_any)
  end

  context 'when use default join operator' do
    it 'should return collection with tag ruby' do
      expect(ViewPost.tagged_with_any('ruby').size).to eq(2)
    end

    it 'should return collection with tag php' do
      expect(ViewPost.tagged_with_any('php').size).to eq(1)
    end

    it 'should return collection with tags elixir, rails, ruby' do
      expect(ViewPost.tagged_with_any('elixir, rails, ruby').size).to eq(2)
    end
  end

  context 'when use AND as join operator' do
    it 'should return collection with tag ruby' do
      expect(ViewPost.tagged_with_any('ruby', join_operator: 'and').size).to eq(1)
    end

    it 'should return collection with tag php' do
      expect(ViewPost.tagged_with_any('php', join_operator: 'and').size).to eq(0)
    end

    it 'should return collection with tags elixir, rails, ruby' do
      expect(ViewPost.tagged_with_any('elixir, rails, ruby', join_operator: 'and').size).to eq(1)
    end
  end
end
