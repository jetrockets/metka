# frozen_string_literal: true

require "test_helper"

# IndexedPost reads the same posts table as Post, but declares index_tables,
# so on SQLite its tag queries answer from the trigger-maintained side
# tables. Whatever Post returns, IndexedPost must return — on both adapters.
class IndexedPostTest < ActiveSupport::TestCase
  SQLITE = ActiveRecord::Base.connection.adapter_name.match?(/sqlite/i)

  TAG_INPUTS = [
    "ruby",
    "ruby, elixir",
    "programming",
    "php, backend",
    "ruby, programming",
    "nonexistent",
    "ruby, nonexistent"
  ].freeze

  OPTION_SETS = [
    {},
    { any: true },
    { exclude: true },
    { any: true, exclude: true },
    { on: [ "tags" ] },
    { on: [ "categories" ], any: true },
    { join_operator: Metka::AND }
  ].freeze

  test "returns exactly what the unindexed model returns, across inputs and options" do
    TAG_INPUTS.each do |tags|
      OPTION_SETS.each do |options|
        expected = Post.tagged_with(tags, **options).ids.sort
        actual = IndexedPost.tagged_with(tags, **options).ids.sort

        assert_equal expected, actual, "diverged for #{tags.inspect} with #{options.inspect}"
      end
    end
  end

  test "column scopes match the unindexed model" do
    assert_equal Post.with_all_tags("ruby").ids.sort, IndexedPost.with_all_tags("ruby").ids.sort
    assert_equal Post.with_any_categories("ruby, backend").ids.sort,
      IndexedPost.with_any_categories("ruby, backend").ids.sort
    assert_equal Post.without_all_tags("ruby").ids.sort, IndexedPost.without_all_tags("ruby").ids.sort
  end

  test "stays correct through creates, updates and deletes" do
    post = IndexedPost.create!(user: users(:david), tag_list: "fresh, ruby")
    assert_includes IndexedPost.with_all_tags("fresh").ids, post.id

    post.update!(tag_list: "stale")
    refute_includes IndexedPost.with_any_tags("fresh, ruby").ids, post.id
    assert_includes IndexedPost.with_all_tags("stale").ids, post.id

    post.destroy!
    assert_empty IndexedPost.with_all_tags("stale")
  end

  test "raises when index_tables name a column that is not tagged" do
    error = assert_raises(ArgumentError) {
      Metka::Model(column: "tags", index_tables: { "bogus" => "some_table" })
    }
    assert_match(/index_tables declared for unknown columns \["bogus"\]/, error.message)
  end

  if SQLITE
    test "answers ALL queries with an INTERSECT of index seeks" do
      sql = IndexedPost.tagged_with("ruby, elixir", on: [ "tags" ]).to_sql

      assert_match(/"posts"\."id" IN \(SELECT record_id FROM "posts_tags_index" WHERE tag_name = 'ruby' INTERSECT SELECT record_id FROM "posts_tags_index" WHERE tag_name = 'elixir'\)/, sql)
      assert_no_match(/json_each/, sql)
    end

    test "answers ANY queries with a single IN probe" do
      sql = IndexedPost.tagged_with("ruby, elixir", on: [ "categories" ], any: true).to_sql

      assert_match(/"posts"\."id" IN \(SELECT record_id FROM "posts_categories_index" WHERE tag_name IN \('ruby','elixir'\)\)/, sql)
      assert_no_match(/json_each/, sql)
    end

    test "keeps the index tables in step with a live aggregation after a mixed workload" do
      IndexedPost.create!(user: users(:david), tag_list: [ "a", "b" ])
      Post.create!(user: users(:david), tag_list: [ "b" ], category_list: [ "c" ])
      Post.update_all("tags = json_insert(COALESCE(tags, '[]'), '$[#]', 'z')")
      Post.where(id: Post.with_all_tags("php").ids).delete_all
      posts(:ruby_post).update!(tag_list: nil)

      %w[tags categories].each do |column|
        live = IndexedPost.connection.select_rows(<<~SQL).sort
          SELECT DISTINCT value, posts.id FROM posts, json_each(posts.#{column})
        SQL
        indexed = IndexedPost.connection.select_rows("SELECT tag_name, record_id FROM posts_#{column}_index").sort

        assert_equal live, indexed, "index table for #{column} drifted"
      end
    end
  end
end
