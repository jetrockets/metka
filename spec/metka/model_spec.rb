# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metka::Model, :db do
  let!(:tag_list) { 'ruby, rails, crystal' }
  let!(:material_list) { 'steel | wood | rock' }
  let!(:user) { User.create(name: Faker::Name.name) }
  let!(:view_post) { ViewPost.new(user_id: user.id) }
  let!(:view_post_two) { ViewPost.new(user_id: user.id) }
  let!(:user1) { User.create!(name: Faker::Name.name, tags: %w[author best_selling]) }
  let!(:user2) { User.create!(name: Faker::Name.name, tags: ['follower']) }

  before do
    view_post.tag_list = tag_list
    view_post.material_list = material_list
    view_post.save!

    view_post_two.tag_list = ['php', 'java', 'scala']
    view_post_two.save!
  end

  context 'when as tags use tags' do
    describe '.with_all_tags' do
      it 'should respond to .with_all_tags' do
        expect(ViewPost).to respond_to(:with_all_tags)
      end

      it 'should be able to find by tag' do
        expect(ViewPost.with_all_tags(tag_list)).to be_present
        expect(ViewPost.with_all_tags(tag_list.split(', ').first)).to be_present
        expect(ViewPost.with_all_tags(tag_list.split(', ').last)).to be_present
        expect(ViewPost.with_all_tags(tag_list).first).to eq(view_post)
      end

      it 'should return an empty scope for empty tags' do
        expect(ViewPost.with_all_tags('')).to be_empty
      end

      it 'should return an empty scope for unused tags' do
        finding_tags = [tag_list.split(', ').first, 'PHP']
        expect(ViewPost.with_all_tags(finding_tags)).to be_empty
      end
    end

    describe '.with_any' do
      let(:new_tag_list) { tag_list + 'Go' }

      it 'should respond to .with_any method' do
        expect(ViewPost).to respond_to(:with_any_tags)
      end

      it 'should be able to find by tag' do
        expect(ViewPost.with_any_tags(new_tag_list)).to be_present
        expect(ViewPost.with_any_tags(new_tag_list.split(', ').first)).to be_present
        expect(ViewPost.with_any_tags(new_tag_list).first).to eq(view_post)
      end

      it 'should return an empty scope for unused tags' do
        expect(ViewPost.with_any_tags(new_tag_list.split(', ').last)).to be_empty
      end
    end

    describe '.without_all_tags' do
      it 'should respond to .without_all_tags' do
        expect(ViewPost).to respond_to(:without_all_tags)
      end

      it 'should return two object if tags empty' do
        ['', nil, []].each do |tags|
          expect(ViewPost.without_all_tags(tags).size).to eq(0)
        end
      end

      it 'should return post' do
        expect(ViewPost.without_all_tags(view_post_two.tag_list.to_a).first).to eq(view_post)
        expect(ViewPost.without_all_tags(view_post.tag_list.to_a).first).to eq(view_post_two)
      end

      it 'should return all view post if posts dont include all tags' do
        expect(ViewPost.without_all_tags(view_post_two.tag_list.to_a << '123').count).to eq(2)
      end
    end

    describe '.without_any_tags' do
      it 'should respond to .without_any_tags' do
        expect(ViewPost).to respond_to(:without_any_tags)
      end

      it 'should return view_post' do
        expect(ViewPost.without_any_tags(view_post_two.tag_list.to_a << 'Clojure').count).to eq(1)
        expect(ViewPost.without_any_tags(view_post_two.tag_list.to_a << 'Clojure').first).to eq(view_post)
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
