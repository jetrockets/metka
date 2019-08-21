# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metka::Model, :db do  
  context 'class methods' do
    let(:tag_list) { 'ruby, rails, crystal' }
    
    let(:user) do
      User.new(name: Faker::Name.name)
    end

    let(:taggable) do
      Post.new.tap do |p|
        p.user = user
        p.title = Faker::Book.title
        p.tag_list = tag_list
      end
    end
    
    describe '#tagged_with' do
      it 'should respond to #tagged_with method' do
        expect(Post).to respond_to(:tagged_with)
      end

      it 'should return an empty scope for empty tags' do
        ['', ' ', nil, []].each do |tag|
          expect(Post.tagged_with(tag)).to be_empty
        end
      end

      it 'should be able to find by tag' do
        taggable.save!
        expect(Post.tagged_with('ruby').first).to eq(taggable)
      end

      it 'should be able to get a count with find by tag when using a group by' do
        taggable.save!    
        expect(Post.tagged_with('ruby').group(:created_at).count.count).to eq(1)
      end

      it 'can be used as scope' do
        taggable.save!

        scope_tag = Post.tagged_with('ruby')
        expect(User.joins(:posts).merge(scope_tag).except(:select)).to eq([user])
      end    
    end
  end
end