# frozen_string_literal: true

require "test_helper"

class TaggedMaterializedViewPostTest < ActiveSupport::TestCase
  TAG1 = "tag1"
  TAG2 = "tag2"
  UNUSED_TAG = "tag3"

  setup do
    @user = User.create(name: Faker::Name.name)
    @materialized_view_post_1 = MaterializedViewPost.create(user_id: @user.id, tag_list: TAG1)
    @materialized_view_post_2 = MaterializedViewPost.create(user_id: @user.id, tag_list: [ TAG1, TAG2 ])
  end

  test "has objects" do
    assert_predicate TaggedMaterializedViewPost.all, :present?
  end

  test "has right taggings count" do
    assert_equal 2, TaggedMaterializedViewPost.find_by(tag_name: TAG1).taggings_count
    assert_equal 1, TaggedMaterializedViewPost.find_by(tag_name: TAG2).taggings_count
  end

  test "has uniq tag_name" do
    assert_equal 1, TaggedMaterializedViewPost.where(tag_name: TAG1).count
  end

  test "dont have unused tag" do
    assert_empty TaggedMaterializedViewPost.where(tag_name: UNUSED_TAG)
  end

  test "increases the counter on post with tag addition" do
    assert_difference -> { taggings_count(TAG2) }, 1 do
      MaterializedViewPost.create(user_id: @user.id, tag_list: TAG2)
    end
  end

  test "decreases the counter on post with tag removal" do
    assert_difference -> { taggings_count(TAG1) }, -1 do
      @materialized_view_post_1.delete
    end
  end

  test "increases the counter on post tags expansion via update" do
    assert_difference -> { taggings_count(TAG2) }, 1 do
      @materialized_view_post_1.update(tag_list: [ TAG1, TAG2 ])
    end
  end

  test "decreases the counter on post tags narrowing via update" do
    assert_difference -> { taggings_count(TAG1) }, -1 do
      @materialized_view_post_2.update(tag_list: TAG2)
    end
  end

  test "decreases the counter on post tags nullify" do
    assert_difference -> { taggings_count(TAG1) }, -1 do
      @materialized_view_post_1.update(tag_list: nil)
    end
  end

  private def taggings_count(tag_name)
    TaggedMaterializedViewPost.find_by(tag_name: tag_name)&.taggings_count.to_i
  end
end
