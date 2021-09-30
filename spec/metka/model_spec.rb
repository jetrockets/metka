# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metka::Model, :db do
  let!(:tag_list) { 'ruby, rails, crystal' }
  let!(:category_list) { 'programming, backend, frontend' }

  let!(:user) { User.create(name: Faker::Name.name) }
  let!(:user1) { User.create!(name: Faker::Name.name, tags: %w[developer senior]) }
  let!(:user2) { User.create!(name: Faker::Name.name, tags: ['junior']) }
  let!(:post) { Post.new(user_id: user.id) }
  let!(:post_two) { Post.new(user_id: user.id) }

  before do
    post.tag_list = tag_list
    post.category_list = category_list
    post.save!

    post_two.tag_list = ['php', 'java', 'scala']
    post_two.save!
  end

  context 'with default parser' do
    describe '.with_all_tags' do
      it 'responds to .with_all_tags' do
        expect(Post).to respond_to(:with_all_tags)
      end

      it 'is able to find by tag' do
        expect(Post.with_all_tags(tag_list)).to be_present
        expect(Post.with_all_tags(tag_list.split(', ').first)).to be_present
        expect(Post.with_all_tags(tag_list.split(', ').last)).to be_present
        expect(Post.with_all_tags(tag_list).first).to eq(post)
      end

      it 'returns a not empty scope for empty tags' do
        expect(Post.with_all_tags('')).not_to be_empty
      end

      it 'returns an empty scope for unused tags' do
        finding_tags = [tag_list.split(', ').first, 'PHP']
        expect(Post.with_all_tags(finding_tags)).to be_empty
      end
    end

    describe '.with_any' do
      let(:new_tag_list) { tag_list + ', go' }

      it 'responds to .with_any method' do
        expect(Post).to respond_to(:with_any_tags)
      end

      it 'is able to find by tag' do
        expect(Post.with_any_tags(new_tag_list)).to be_present
        expect(Post.with_any_tags(new_tag_list.split(', ').first)).to be_present
        expect(Post.with_any_tags(new_tag_list).first).to eq(post)
      end

      it 'returns an empty scope for unused tags' do
        expect(Post.with_any_tags(new_tag_list.split(', ').last)).to be_empty
      end
    end

    describe '.without_all_tags' do
      it 'responds to .without_all_tags' do
        expect(Post).to respond_to(:without_all_tags)
      end

      it 'returns two object if tags empty' do
        ['', nil, []].each do |tags|
          expect(Post.without_all_tags(tags).size).to eq(Post.count)
        end
      end

      it 'returns post' do
        expect(Post.without_all_tags(post_two.tag_list.to_a).first).to eq(post)
        expect(Post.without_all_tags(post.tag_list.to_a).first).to eq(post_two)
      end

      it 'returns all post if posts dont include all tags' do
        expect(Post.without_all_tags(post_two.tag_list.to_a << '123').count).to eq(2)
      end
    end

    describe '.without_any_tags' do
      it 'responds to .without_any_tags' do
        expect(Post).to respond_to(:without_any_tags)
      end

      it 'returns post' do
        expect(Post.without_any_tags(post_two.tag_list.to_a << 'Clojure').count).to eq(1)
        expect(Post.without_any_tags(post_two.tag_list.to_a << 'Clojure').first).to eq(post)
      end
    end

    describe '.tagged_with' do
      specify do
        post.tags << 'php'
        post.save!

        expect(Post.tagged_with(%w[php ruby]).count).to eq(1)
        expect(Post.tagged_with(%w[php ruby]).first).to eq(post)
      end

      specify do
        expect(Post.tagged_with(%w[php cobol], any: true).count).to eq(1)
        expect(Post.tagged_with(%w[php cobol], any: true).first).to eq(post_two)
      end

      specify do
        expect(Post.tagged_with(%w[php], exclude: true).count).to eq(1)
        expect(Post.tagged_with(%w[php], exclude: true).first).to eq(post)
      end

      specify do
        post.tags << 'php'
        post.save!

        expect(Post.tagged_with(%w[php ruby], any: false).count).to eq(1)
        expect(Post.tagged_with(%w[php ruby], any: false).first).to eq(post)
      end

      specify do
        expect(Post.tagged_with('php', on: ['categories'])).to eq []
        expect(Post.tagged_with('ruby', on: ['tags']).count).to eq(1)
        expect(Post.tagged_with('ruby', on: ['tags']).first).to eq(post)
      end

      specify do
        ['', nil, []].each do |tags|
          expect(Post.tagged_with(tags, any: false)).to eq(Post.all)
          expect(Post.tagged_with(tags, any: true)).to eq(Post.all)
          expect(Post.tagged_with(tags, exclude: true, any: true)).to eq(Post.all)
          expect(Post.tagged_with(tags, exclude: true, any: false)).to eq(Post.all)
        end
      end
    end
  end

  context 'with custom parser' do
    let(:tags) { 'developer | senior' }

    describe '.with_all_tags' do
      it 'responds to .with_all_tags' do
        expect(User).to respond_to(:with_all_tags)
      end

      it 'is able to find by tags' do
        expect(User.with_all_tags(tags)).to be_present
        expect(User.with_all_tags(tags.split(' | ').first)).to be_present
        expect(User.with_all_tags(tags).first).to eq(user1)
      end

      it 'returns a not empty scope for empty categories' do
        expect(User.with_all_tags('')).not_to be_empty
      end

      it 'returns an empty scope for unused categories' do
        finding_tags = [tags.split(' | ').first, 'junior']
        expect(User.with_all_tags(finding_tags)).to be_empty
      end
    end

    describe '.with_any_tags' do
      let(:new_tags_list) { tags + ' | backend' }

      it 'responds to .with_any_tags' do
        expect(User).to respond_to(:with_any_tags)
      end

      it 'is able to find by category' do
        expect(User.with_any_tags(new_tags_list)).to be_present
        expect(User.with_any_tags(new_tags_list.split(' | ').first)).to be_present
        expect(User.with_any_tags(new_tags_list).first).to eq(user1)
      end

      it 'returns an empty scope for unused tags' do
        expect(User.with_any_tags(new_tags_list.split(' | ').last)).to be_empty
      end
    end
  end
end
