# frozen_string_literal: true

require "test_helper"

class MetkaTagsQueryTest < ActiveSupport::TestCase
  test "matches a single tag with ANY regardless of match mode" do
    assert_equal %('ruby' = ANY("posts"."tags")),
      Metka::TagsQuery.new(match: :all).call(Post, "tags", [ "ruby" ]).to_sql
    assert_equal %('ruby' = ANY("posts"."tags")),
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

  test "raises on an unknown match mode" do
    assert_raises(KeyError) { Metka::TagsQuery.new(match: :some) }
  end
end
