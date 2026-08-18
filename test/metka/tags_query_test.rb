# frozen_string_literal: true

require "test_helper"

class MetkaTagsQueryTest < ActiveSupport::TestCase
  SQLITE = ActiveRecord::Base.connection.adapter_name.match?(/sqlite/i)

  if SQLITE
    test "matches a single tag with an EXISTS over json_each" do
      assert_equal %{(EXISTS (SELECT 1 FROM json_each("posts"."tags") WHERE value = 'ruby'))},
        Metka::TagsQuery.new(match: :all).call(Post, "tags", [ "ruby" ]).to_sql
      assert_equal %{(EXISTS (SELECT 1 FROM json_each("posts"."tags") WHERE value IN ('ruby')))},
        Metka::TagsQuery.new(match: :any).call(Post, "tags", [ "ruby" ]).to_sql
    end

    test "matches every tag with one EXISTS per tag" do
      expected = %{(EXISTS (SELECT 1 FROM json_each("posts"."tags") WHERE value = 'ruby') } +
        %{AND EXISTS (SELECT 1 FROM json_each("posts"."tags") WHERE value = 'rails'))}
      assert_equal expected,
        Metka::TagsQuery.new(match: :all).call(Post, "tags", [ "ruby", "rails" ]).to_sql
    end

    test "matches any tag with a single IN list" do
      assert_equal %{(EXISTS (SELECT 1 FROM json_each("posts"."tags") WHERE value IN ('ruby','rails')))},
        Metka::TagsQuery.new(match: :any).call(Post, "tags", [ "ruby", "rails" ]).to_sql
    end

    test "matches every tag by default" do
      assert_equal Metka::TagsQuery.new(match: :all).call(Post, "tags", [ "ruby", "rails" ]).to_sql,
        Metka::TagsQuery.new.call(Post, "tags", [ "ruby", "rails" ]).to_sql
    end

    test "queries the column it is given" do
      assert_equal %{(EXISTS (SELECT 1 FROM json_each("posts"."categories") WHERE value IN ('ruby')))},
        Metka::TagsQuery.new(match: :any).call(Post, "categories", [ "ruby" ]).to_sql
    end
  else
    test "matches a single tag with the array operators so GIN indexes apply" do
      assert_equal %("posts"."tags" @> ARRAY['ruby']::varchar[]),
        Metka::TagsQuery.new(match: :all).call(Post, "tags", [ "ruby" ]).to_sql
      assert_equal %("posts"."tags" && ARRAY['ruby']::varchar[]),
        Metka::TagsQuery.new(match: :any).call(Post, "tags", [ "ruby" ]).to_sql
    end

    test "matches every tag with @>" do
      assert_equal %("posts"."tags" @> ARRAY['ruby','rails']::varchar[]),
        Metka::TagsQuery.new(match: :all).call(Post, "tags", [ "ruby", "rails" ]).to_sql
    end

    test "matches any tag with &&" do
      assert_equal %("posts"."tags" && ARRAY['ruby','rails']::varchar[]),
        Metka::TagsQuery.new(match: :any).call(Post, "tags", [ "ruby", "rails" ]).to_sql
    end

    test "matches every tag by default" do
      assert_equal %("posts"."tags" @> ARRAY['ruby','rails']::varchar[]),
        Metka::TagsQuery.new.call(Post, "tags", [ "ruby", "rails" ]).to_sql
    end

    test "queries the column it is given" do
      assert_equal %("posts"."categories" @> ARRAY['ruby','rails']::varchar[]),
        Metka::TagsQuery.new.call(Post, "categories", [ "ruby", "rails" ]).to_sql
    end
  end

  test "raises on an unknown match mode" do
    assert_raises(KeyError) { Metka::TagsQuery.new(match: :some) }
  end
end
