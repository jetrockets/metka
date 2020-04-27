# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metka::Model, :db do
  let!(:tag_list)      { 'ruby, rails, crystal' }
  let!(:material_list) { 'steel | wood | rock' }

  let!(:user)     { User.create(name: Faker::Name.name) }
  let!(:user1)    { User.create!(name: Faker::Name.name, tags: %w[author best_selling]) }
  let!(:user2)    { User.create!(name: Faker::Name.name, tags: ['follower']) }
  let!(:post)     { Post.new(user_id: user.id)}
  let!(:post_two) { Post.new(user_id: user.id)}

  before do
    post.tag_list = tag_list
    post.material_list = material_list
    post.save!

    post_two.tag_list = ['php', 'java', 'scala']
    post_two.save!
  end

  context 'when as tags use tags' do
    describe '.with_all_tags' do
      it 'should respond to .with_all_tags' do
        expect(Post).to respond_to(:with_all_tags)
      end

      it 'should be able to find by tag' do
        expect(Post.with_all_tags(tag_list)).to be_present
        expect(Post.with_all_tags(tag_list.split(', ').first)).to be_present
        expect(Post.with_all_tags(tag_list.split(', ').last)).to be_present
        expect(Post.with_all_tags(tag_list).first).to eq(post)
      end

      it 'should return an empty scope for empty tags' do
        expect(Post.with_all_tags('')).to be_empty
      end

      it 'should return an empty scope for unused tags' do
        finding_tags = [tag_list.split(', ').first, 'PHP']
        expect(Post.with_all_tags(finding_tags)).to be_empty
      end
    end

    describe '.with_any' do
      let(:new_tag_list) { tag_list + 'Go' }

      it 'should respond to .with_any method' do
        expect(Post).to respond_to(:with_any_tags)
      end

      it 'should be able to find by tag' do
        expect(Post.with_any_tags(new_tag_list)).to be_present
        expect(Post.with_any_tags(new_tag_list.split(', ').first)).to be_present
        expect(Post.with_any_tags(new_tag_list).first).to eq(post)
      end

      it 'should return an empty scope for unused tags' do
        expect(Post.with_any_tags(new_tag_list.split(', ').last)).to be_empty
      end
    end

    describe '.without_all_tags' do
      it 'should respond to .without_all_tags' do
        expect(Post).to respond_to(:without_all_tags)
      end

      it 'should return two object if tags empty' do
        ['', nil, []].each do |tags|
          expect(Post.without_all_tags(tags).size).to eq(0)
        end
      end

      it 'should return post' do
        expect(Post.without_all_tags(post_two.tag_list.to_a).first).to eq(post)
        expect(Post.without_all_tags(post.tag_list.to_a).first).to eq(post_two)
      end

      it 'should return all view post if posts dont include all tags' do
        expect(Post.without_all_tags(post_two.tag_list.to_a << '123').count).to eq(2)
      end
    end

    describe '.without_any_tags' do
      it 'should respond to .without_any_tags' do
        expect(Post).to respond_to(:without_any_tags)
      end

      it 'should return post' do
        expect(Post.without_any_tags(post_two.tag_list.to_a << 'Clojure').count).to eq(1)
        expect(Post.without_any_tags(post_two.tag_list.to_a << 'Clojure').first).to eq(post)
      end
    end

    describe '.tagged_with' do
      specify do
        view_post.tags << 'php'
        view_post.save!

        expect(ViewPost.tagged_with(%w[php ruby]).count).to eq(1)
        expect(ViewPost.tagged_with(%w[php ruby]).first).to eq(view_post)
      end

      specify do
        expect(ViewPost.tagged_with(%w[php cobol], any: true).count).to eq(1)
        expect(ViewPost.tagged_with(%w[php cobol], any: true).first).to eq(view_post_two)
      end

      specify do
        expect(ViewPost.tagged_with(%w[php], exclude: true).count).to eq(1)
        expect(ViewPost.tagged_with(%w[php], exclude: true).first).to eq(view_post)
      end

      specify do
        view_post.tags << 'php'
        view_post.save!

        expect(ViewPost.tagged_with(%w[php ruby], any: false).count).to eq(1)
        expect(ViewPost.tagged_with(%w[php ruby], any: false).first).to eq(view_post)
      end

      specify do
        expect(ViewPost.tagged_with('php', on: ['materials'])).to eq []
        expect(ViewPost.tagged_with('ruby', on: ['tags']).count).to eq(1)
        expect(ViewPost.tagged_with('ruby', on: ['tags']).first).to eq(view_post)
      end

      specify do
        ['', nil, []].each do |tags|
          expect(ViewPost.tagged_with(tags, any: false)).to eq(ViewPost.none)
          expect(ViewPost.tagged_with(tags, any: true)).to eq(ViewPost.none)
          expect(ViewPost.tagged_with(tags, exclude: true, any: true)).to eq(ViewPost.none)
          expect(ViewPost.tagged_with(tags, exclude: true, any: false)).to eq(ViewPost.none)
        end
      end
    end
  end

  context 'when as tags use materials' do
    let(:tags)       { "author | best_selling" }

    describe '.with_all_tags' do
      it 'should respond to .with_all_tags' do
        expect(User).to respond_to(:with_all_tags)
      end

      it 'should be able to find by tags' do
        expect(User.with_all_tags(tags)).to be_present
        expect(User.with_all_tags(tags.split(' | ').first)).to be_present
        expect(User.with_all_tags(tags).first).to eq(user1)
      end

      it 'should return an empty scope for empty materials' do
        expect(User.with_all_tags('')).to be_empty
      end

      it 'should return an empty scope for unused materials' do
        finding_tags = [tags.split(' | ').first, 'follower']
        expect(User.with_all_tags(finding_tags)).to be_empty
      end
    end

    describe '.with_any_tags' do
      let(:new_tags_list) { tags + ' | iron' }

      it 'should respond to .with_any_tags' do
        expect(User).to respond_to(:with_any_tags)
      end

      it 'should be able to find by material' do
        expect(User.with_any_tags(new_tags_list)).to be_present
        expect(User.with_any_tags(new_tags_list.split(' | ').first)).to be_present
        expect(User.with_any_tags(new_tags_list).first).to eq(user1)
      end

      it 'should return an empty scope for unused tags' do
        expect(User.with_any_tags(new_tags_list.split(' | ').last)).to be_empty
      end
    end
  end
end
