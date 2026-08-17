# frozen_string_literal: true

require "test_helper"

class TaggedWithTagsAndCategoriesMaterializedViewMultitagPostTest < ActiveSupport::TestCase
  TAG1 = "tag1"
  TAG2 = "tag2"
  CATEGORY1 = "category1"
  CATEGORY2 = "category2"
  SHARED_TAG = "sharedtag"
  UNUSED_TAG = "tag3"

  setup do
    @user = User.create(name: Faker::Name.name)
    @materialized_view_multitag_post_1 = MaterializedViewMultitagPost.create(
      user_id: @user.id,
      tag_list: [ TAG1, SHARED_TAG ],
      category_list: [ CATEGORY1, CATEGORY2 ]
    )
    @materialized_view_multitag_post_2 = MaterializedViewMultitagPost.create(
      user_id: @user.id,
      tag_list: [ TAG1, TAG2 ],
      category_list: [ CATEGORY2, SHARED_TAG ]
    )
  end

  test "has objects" do
    assert_predicate TaggedWithTagsAndCategoriesMaterializedViewMultitagPost.all, :present?
  end

  test "has correct tags taggings count" do
    assert_equal 2, taggings_count(TAG1)
    assert_equal 1, taggings_count(TAG2)
  end

  test "has correct categories taggings count" do
    assert_equal 1, taggings_count(CATEGORY1)
    assert_equal 2, taggings_count(CATEGORY2)
  end

  test "correctly sums tags that are shared between taggable columns" do
    assert_equal 2, taggings_count(SHARED_TAG)
  end

  test "has uniq tag_name" do
    assert_equal 1, TaggedWithTagsAndCategoriesMaterializedViewMultitagPost.where(tag_name: TAG1).count
  end

  test "dont have unused tag" do
    assert_empty TaggedWithTagsAndCategoriesMaterializedViewMultitagPost.where(tag_name: UNUSED_TAG)
  end

  test "increases the counter on post with tag addition" do
    assert_difference [ -> { taggings_count(TAG2) }, -> { taggings_count(CATEGORY1) } ], 1 do
      MaterializedViewMultitagPost.create(user_id: @user.id, tag_list: TAG2, category_list: CATEGORY1)
    end
  end

  test "decreases the counter on post with tag removal" do
    counters = [
      -> { taggings_count(TAG1) },
      -> { taggings_count(SHARED_TAG) },
      -> { taggings_count(CATEGORY1) },
      -> { taggings_count(CATEGORY2) }
    ]

    assert_difference counters, -1 do
      @materialized_view_multitag_post_1.delete
    end
  end

  test "increases the counter on post tags expansion via update" do
    counters = {
      -> { taggings_count(TAG2) } => 1,
      -> { taggings_count(SHARED_TAG) } => -1
    }

    assert_difference counters do
      @materialized_view_multitag_post_1.update(tag_list: [ TAG1, TAG2 ])
    end
  end

  test "decreases the counter on post tags narrowing via update" do
    assert_difference -> { taggings_count(SHARED_TAG) }, -1 do
      @materialized_view_multitag_post_2.update(category_list: CATEGORY2)
    end
  end

  test "decreases the counter on post tags nullify" do
    assert_difference [ -> { taggings_count(TAG1) }, -> { taggings_count(SHARED_TAG) } ], -1 do
      @materialized_view_multitag_post_1.update(tag_list: nil)
    end
  end

  private def taggings_count(tag_name)
    TaggedWithTagsAndCategoriesMaterializedViewMultitagPost.find_by(tag_name: tag_name)&.taggings_count.to_i
  end
end
