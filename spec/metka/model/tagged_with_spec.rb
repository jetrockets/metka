# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metka::Model, :db do
  let!(:tag_list) { 'ruby, rails, crystal' }
  let!(:tag_list_2) { 'php, java, scala'}
  let!(:material_list) { 'steel, wood, rock, scala' }
  let!(:user) { User.create(name: Faker::Name.name) }
  let!(:view_post) { ViewPost.new(user_id: user.id)}
  let!(:view_post_two) { ViewPost.new(user_id: user.id)}

  describe '.tagged_with_any' do
    before do
      view_post.tag_list = tag_list
      view_post.material_list = material_list
      view_post.save!

      view_post_two.tag_list = tag_list_2
      view_post_two.save!
    end

    it 'should respond to .tagged_with_any' do
      expect(ViewPost).to respond_to(:tagged_with_any)
    end

    it 'should return two object' do
      tags_for_search = [material_list.split(', ').sample, tag_list_2.split(', ').sample]
      expect(ViewPost.tagged_with_any(tags_for_search).size).to eq(2)
    end

    it 'should return view_post if tag from him' do
      expect(ViewPost.tagged_with_any(tag_list.split(', ').sample).size).to eq(1)
      expect(ViewPost.tagged_with_any(tag_list.split(', ').sample).first).to eq(view_post)
    end
  end

  describe '.tagged_with_all' do
    before do
      view_post = ViewPost.new(user_id: user.id)
      view_post.material_list = 'qwer, tyui'
      view_post.save!

      view_post = ViewPost.new(user_id: user.id)
      view_post.tag_list = 'qwer'
      view_post.save!
    end

    it 'should respond to .tagged_with_all' do
      expect(ViewPost).to respond_to(:tagged_with_all)
    end

    it 'should return ...' do
      expect(ViewPost.tagged_with_all('qwer' ).size).to eq(2)
      expect(ViewPost.tagged_with_all('qwer, tyui' ).size).to eq(1)
      expect(ViewPost.tagged_with_all('tyui' ).size).to eq(1)
      expect(ViewPost.tagged_with_all('qwer1, tyui1' ).size).to eq(0)
    end
  end

  describe '.tagged_without_any' do
    before do
      view_post = ViewPost.new(user_id: user.id)
      view_post.material_list = 'qwer, tyui'
      view_post.save!

      view_post = ViewPost.new(user_id: user.id)
      view_post.tag_list = 'qwer'
      view_post.save!

      view_post = ViewPost.new(user_id: user.id)
      view_post.tag_list = 'qwer1'
      view_post.save!
    end

    it 'should respond to .tagged_without_all' do
      expect(ViewPost).to respond_to(:tagged_without_all)
    end

    it 'should return ...' do
      expect(ViewPost.tagged_without_all('tyui').size).to eq(2)
      expect(ViewPost.tagged_without_all('qwer').size).to eq(1)
      expect(ViewPost.tagged_without_all('qwer1').size).to eq(2)
      expect(ViewPost.tagged_without_all('qwer, tyui').size).to eq(2)
      expect(ViewPost.tagged_without_all('qwer, tyui, asdasd').size).to eq(3)
    end
  end


  describe '.tagged_without_any' do
    before do
      view_post = ViewPost.new(user_id: user.id)
      view_post.material_list = 'asd, zxc'
      view_post.save!

      view_post = ViewPost.new(user_id: user.id)
      view_post.tag_list = 'asd'
      view_post.save!

      view_post = ViewPost.new(user_id: user.id)
      view_post.tag_list = 'asd1'
      view_post.save!
    end

    it 'should respond to .tagged_without_any' do
      expect(ViewPost).to respond_to(:tagged_without_any)
    end

    it 'should return ...' do
      expect(ViewPost.tagged_without_any('asd').size).to eq(1)
      expect(ViewPost.tagged_without_any('asd, asd1').size).to eq(0)
      expect(ViewPost.tagged_without_any('asd, zxc').size).to eq(1)
      expect(ViewPost.tagged_without_any('zxc, sdfdsf').size).to eq(2)
    end
  end
end