# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metka::Model, :db do
  let!(:tag_list) { 'ruby, rails, crystal' }
  let!(:material_list) { 'steel, wood, rock' }
  let!(:user) { User.create(name: Faker::Name.name) }
  let!(:view_post) { ViewPost.new(user_id: user.id)}
  let!(:view_post_two) { ViewPost.new(user_id: user.id)}

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
      let(:new_tag_list) { tag_list + 'Go'}

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
        expect(ViewPost.without_all_tags('').size).to eq(2)
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
  end

  context 'when as tags use materials' do
    describe '.with_all_materials' do
      it 'should respond to .with_all_materials' do
        expect(ViewPost).to respond_to(:with_all_materials)
      end

      it 'should be able to find by material' do
        expect(ViewPost.with_all_materials(material_list)).to be_present
        expect(ViewPost.with_all_materials(material_list.split(', ').first)).to be_present
        expect(ViewPost.with_all_materials(material_list.split(', ').last)).to be_present
        expect(ViewPost.with_all_materials(material_list).first).to eq(view_post)
      end

      it 'should return an empty scope for empty materials' do
        expect(ViewPost.with_all_materials('')).to be_empty
      end

      it 'should return an empty scope for unused materials' do
        finding_materials = [material_list.split(', ').first, 'PHP']
        expect(ViewPost.with_all_materials(finding_materials)).to be_empty
      end
    end

    describe '.with_any_materials' do
      let(:new_material_list) { material_list + 'iron'}

      it 'should respond to .with_any_materials' do
        expect(ViewPost).to respond_to(:with_any_materials)
      end

      it 'should be able to find by material' do
        expect(ViewPost.with_any_materials(new_material_list)).to be_present
        expect(ViewPost.with_any_materials(new_material_list.split(', ').first)).to be_present
        expect(ViewPost.with_any_materials(new_material_list).first).to eq(view_post)
      end

      it 'should return an empty scope for unused tags' do
        expect(ViewPost.with_any_materials(new_material_list.split(', ').last)).to be_empty
      end
    end
  end
end
