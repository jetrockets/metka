# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metka::Post, :model do
  let!(:tag1)       { 'tag1' }
  let!(:tag2)       { 'tag2' }
  let!(:material1)  { 'material1' }
  let!(:material2)  { 'material2' }
  let!(:shared_tag) { 'sharedtag' }
  let!(:unused_tag) { 'tag3' }
  let!(:user)       { User.create(name: Faker::Name.name) }

  let(:tagged_model) { Post }

  context 'tagging clouds' do
    before do
      Post.create(user_id: user.id, tag_list: [tag1, shared_tag], material_list: [material1, material2])
      Post.create(user_id: user.id, tag_list: [tag1, tag2], material_list: [material2, shared_tag])
    end

    specify 'are correctly generated for tags column' do
      expect(tagged_model.tag_cloud).to contain_exactly([tag1, 2], [tag2, 1], [shared_tag, 1])
    end

    specify 'are correctly generated for materials column' do
      expect(tagged_model.material_cloud).to contain_exactly([material1, 1], [material2, 2], [shared_tag, 1])
    end

    specify 'are correctly generated for both tags and materials columns' do
      expect(tagged_model.metka_cloud(:tags, :materials))
        .to contain_exactly([tag1, 2], [tag2, 1], [material1, 1], [material2, 2], [shared_tag, 2])
    end
  end
end
