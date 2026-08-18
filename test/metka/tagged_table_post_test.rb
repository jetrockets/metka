# frozen_string_literal: true

require "test_helper"

class TaggedTablePostTest < ActiveSupport::TestCase
  TAG1 = "tag1"
  TAG2 = "tag2"
  UNUSED_TAG = "tag3"

  # These rows stay in setup rather than moving to fixtures: the summary table
  # is maintained by triggers on INSERT, UPDATE and DELETE, so going through
  # the write path is the behaviour under test.
  setup do
    @table_post_1 = TablePost.create!(user: users(:david), tag_list: TAG1)
    @table_post_2 = TablePost.create!(user: users(:david), tag_list: [ TAG1, TAG2 ])
  end

  test "has objects" do
    assert_predicate TaggedTablePost.all, :present?
  end

  test "has right taggings count" do
    assert_equal 2, TaggedTablePost.find_by(tag_name: TAG1).taggings_count
    assert_equal 1, TaggedTablePost.find_by(tag_name: TAG2).taggings_count
  end

  test "has uniq tag_name" do
    assert_equal 1, TaggedTablePost.where(tag_name: TAG1).count
  end

  test "dont have unused tag" do
    assert_empty TaggedTablePost.where(tag_name: UNUSED_TAG)
  end

  test "increases the counter on post with tag addition" do
    assert_difference -> { taggings_count(TAG2) }, 1 do
      TablePost.create!(user: users(:david), tag_list: TAG2)
    end
  end

  test "does not create rows for a post without tags" do
    assert_no_difference -> { TaggedTablePost.count } do
      TablePost.create!(user: users(:david))
    end
  end

  test "decreases the counter on post with tag removal" do
    assert_difference -> { taggings_count(TAG1) }, -1 do
      @table_post_1.delete
    end
  end

  test "removes the row when the last tagging is deleted" do
    @table_post_2.update!(tag_list: TAG1)
    TablePost.delete_all

    assert_empty TaggedTablePost.where(tag_name: TAG1)
  end

  test "increases the counter on post tags expansion via update" do
    assert_difference -> { taggings_count(TAG2) }, 1 do
      @table_post_1.update(tag_list: [ TAG1, TAG2 ])
    end
  end

  test "decreases the counter on post tags narrowing via update" do
    assert_difference -> { taggings_count(TAG1) }, -1 do
      @table_post_2.update(tag_list: TAG2)
    end
  end

  test "keeps the counters on an update that does not change tags" do
    assert_no_difference -> { taggings_count(TAG1) } do
      @table_post_1.update(title: "New title")
    end
  end

  test "updates the counters after a multi-row insert statement" do
    assert_difference -> { taggings_count(UNUSED_TAG) }, 2 do
      TablePost.insert_all([
        { user_id: users(:david).id, tags: [ UNUSED_TAG ] },
        { user_id: users(:david).id, tags: [ UNUSED_TAG ] }
      ])
    end
  end

  test "updates the counters after a multi-row update statement" do
    assert_difference -> { taggings_count(UNUSED_TAG) }, 2 do
      TablePost.update_all("tags = tags || '{#{UNUSED_TAG}}'")
    end
  end

  test "updates the counters after a multi-row delete statement" do
    assert_difference -> { taggings_count(TAG1) }, -2 do
      TablePost.delete_all
    end
  end

  test "decreases the counter on post tags nullify" do
    assert_difference -> { taggings_count(TAG1) }, -1 do
      @table_post_1.update(tag_list: nil)
    end
  end

  test "matches a live aggregation after a mixed workload" do
    TablePost.create!(user: users(:david), tag_list: [ TAG2, UNUSED_TAG ])
    TablePost.insert_all([
      { user_id: users(:david).id, tags: [ TAG1, UNUSED_TAG ] },
      { user_id: users(:david).id, tags: nil }
    ])
    @table_post_1.update!(tag_list: [ TAG2 ])
    @table_post_2.update!(title: "New title")
    TablePost.update_all("tags = tags || '{#{UNUSED_TAG}}'")
    @table_post_2.delete
    @table_post_1.update!(tag_list: nil)

    live_aggregation = TablePost.connection.select_rows(<<~SQL)
      SELECT tag_name, COUNT(*)
      FROM (SELECT UNNEST(tags) AS tag_name FROM table_posts) subquery
      GROUP BY tag_name
    SQL

    assert_equal live_aggregation.sort,
      TaggedTablePost.pluck(:tag_name, :taggings_count).sort
  end

  private def taggings_count(tag_name)
    TaggedTablePost.find_by(tag_name: tag_name)&.taggings_count.to_i
  end
end
