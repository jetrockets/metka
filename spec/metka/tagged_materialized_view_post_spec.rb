# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metka::TaggedMaterializedViewPost, :model do
  let!(:tag1)       { 'tag1' }
  let!(:tag2)       { 'tag2' }
  let!(:unused_tag) { 'tag3' }
  let!(:user) { User.create(name: Faker::Name.name) }

  let(:tagged_model) { TaggedMaterializedViewPost }

  context 'when has tagged materialized view posts' do
    before do
      MaterializedViewPost.create(user_id: user.id, tag_list: tag1)
      MaterializedViewPost.create(user_id: user.id, tag_list: [tag1, tag2])
    end

    it 'has objects' do
      expect(tagged_model.all.present?).to be_truthy
    end

    it 'has right taggings count' do
      expect(tagged_model.find_by(tag_name: tag1).taggings_count).to eq(2)
      expect(tagged_model.find_by(tag_name: tag2).taggings_count).to eq(1)
    end

    it 'has uniq tag_name' do
      expect(tagged_model.where(tag_name: tag1).count).to eq(1)
    end

    it 'dont have unused tag' do
      expect(tagged_model.where(tag_name: unused_tag)).to be_empty
    end

    it 'increases the counter if add post with tag' do
      old_count = tagged_model.find_by(tag_name: tag2).taggings_count
      MaterializedViewPost.create(user_id: user.id, tag_list: tag2)
      expect(tagged_model.find_by(tag_name: tag2).taggings_count).to be > old_count
    end
  end
end