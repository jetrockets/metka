# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metka::TaggedMaterializedViewPost, :model do
  let!(:tag1) { 'tag1' }
  let!(:tag2) { 'tag2' }
  let!(:unused_tag) { 'tag3' }
  let!(:user) { User.create(name: Faker::Name.name) }

  let(:tagged_model) { TaggedMaterializedViewPost }

  context 'when has tagged materialized view posts' do
    let!(:materialized_view_post_1) { MaterializedViewPost.create(user_id: user.id, tag_list: tag1) }
    let!(:materialized_view_post_2) { MaterializedViewPost.create(user_id: user.id, tag_list: [tag1, tag2]) }

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

    it 'increases the counter on post with tag addition' do
      expect { MaterializedViewPost.create(user_id: user.id, tag_list: tag2) }
        .to change { tagged_model.find_by(tag_name: tag2).taggings_count }
        .by(1)
    end

    it 'decreases the counter on post with tag removal' do
      expect { materialized_view_post_1.delete }
        .to change { tagged_model.find_by(tag_name: tag1).taggings_count }
        .by(-1)
    end

    it 'increases the counter on post tags expansion via update' do
      expect { materialized_view_post_1.update(tag_list: [tag1, tag2]) }
        .to change { tagged_model.find_by(tag_name: tag2).taggings_count }
        .by(1)
    end

    it 'decreases the counter on post tags narrowing via update' do
      expect { materialized_view_post_2.update(tag_list: tag2) }
        .to change { tagged_model.find_by(tag_name: tag1).taggings_count }
        .by(-1)
    end

    it 'decreases the counter on post tags nullify' do
      expect { materialized_view_post_1.update(tag_list: nil) }
        .to change { tagged_model.find_by(tag_name: tag1).taggings_count }
        .by(-1)
    end
  end
end
