# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metka::Post, :model do
  let!(:tag1) { 'tag1' }
  let!(:tag2) { 'tag2' }
  let!(:category1) { 'category1' }
  let!(:category2) { 'category2' }
  let!(:shared_tag) { 'sharedtag' }
  let!(:unused_tag) { 'tag3' }
  let!(:user) { User.create(name: Faker::Name.name) }

  let(:tagged_model) { Post }

  context 'tagging clouds' do
    before do
      Post.create(user_id: user.id, tag_list: [tag1, shared_tag], category_list: [category1, category2])
      Post.create(user_id: user.id, tag_list: [tag1, tag2], category_list: [category2, shared_tag])
    end

    specify 'are correctly generated for tags column' do
      expect(tagged_model.tag_cloud).to contain_exactly([tag1, 2], [tag2, 1], [shared_tag, 1])
    end

    specify 'are correctly generated for categories column' do
      expect(tagged_model.category_cloud).to contain_exactly([category1, 1], [category2, 2], [shared_tag, 1])
    end

    specify 'are correctly generated for both tags and categories columns' do
      expect(tagged_model.metka_cloud(:tags, :categories))
        .to contain_exactly([tag1, 2], [tag2, 1], [category1, 1], [category2, 2], [shared_tag, 2])
    end
  end
end
