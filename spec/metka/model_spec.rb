# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metka::Model, :db do
  context 'class methods' do
    let(:tag_list) { 'ruby, rails, crystal' }

    let(:user) do
      User.new(name: Faker::Name.name)
    end

    let(:taggable_view_post) do
      ViewPost.new.tap do |p|
        p.user = user
        p.title = Faker::Book.title
        p.tag_list = tag_list
      end
    end

    let(:taggable_materialized_view_post) do
      MaterializedViewPost.new.tap do |p|
        p.user = user
        p.title = Faker::Book.title
        p.tag_list = tag_list
      end
    end

    describe '#tagged_with' do
      context 'when use with view post' do
        it 'should respond to #tagged_with method' do
          expect(ViewPost).to respond_to(:tagged_with)
        end

        it 'should return an empty scope for empty tags' do
          ['', ' ', nil, []].each do |tag|
            expect(ViewPost.tagged_with(tag)).to be_empty
          end
        end

        it 'should be able to find by tag' do
          taggable_view_post.save!
          expect(ViewPost.tagged_with('ruby').first).to eq(taggable_view_post)
        end

        it 'should be able to get a count with find by tag when using a group by' do
          taggable_view_post.save!
          expect(ViewPost.tagged_with('ruby').group(:created_at).count.count).to eq(1)
        end

        it 'can be used as scope' do
          taggable_view_post.save!

          scope_tag = ViewPost.tagged_with('ruby')
          expect(User.joins(:view_posts).merge(scope_tag).except(:select)).to eq([user])
        end
      end

      context 'when use with materialized view post' do
        it 'should respond to #tagged_with method' do
          expect(MaterializedViewPost).to respond_to(:tagged_with)
        end

        it 'should return an empty scope for empty tags' do
          ['', ' ', nil, []].each do |tag|
            expect(MaterializedViewPost.tagged_with(tag)).to be_empty
          end
        end

        it 'should be able to find by tag' do
          taggable_materialized_view_post.save!
          expect(MaterializedViewPost.tagged_with('ruby').first).to eq(taggable_materialized_view_post)
        end

        it 'should be able to get a count with find by tag when using a group by' do
          taggable_materialized_view_post.save!
          expect(MaterializedViewPost.tagged_with('ruby').group(:created_at).count.count).to eq(1)
        end

        it 'can be used as scope' do
          taggable_materialized_view_post.save!

          scope_tag = MaterializedViewPost.tagged_with('ruby')
          expect(User.joins(:materialized_view_posts).merge(scope_tag).except(:select)).to eq([user])
        end
      end
    end
  end
end
