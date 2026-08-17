# frozen_string_literal: true

require "test_helper"

class MetkaAllTagsQueryTest < ActiveSupport::TestCase
  MODEL = Post
  COLUMN_NAME = "tags"
  TAG_LIST = [ "ruby", "rails" ].freeze

  setup do
    @query = Metka::AllTagsQuery.instance
  end

  test "responds to .call" do
    assert_respond_to @query, :call
  end

  test "returns Arel::Nodes::InfixOperation object" do
    assert_instance_of Arel::Nodes::InfixOperation, @query.call(MODEL, COLUMN_NAME, TAG_LIST)
  end

  test "returns correct sql" do
    assert_equal %("posts"."tags" @> ARRAY['ruby','rails']::varchar[]),
      @query.call(MODEL, COLUMN_NAME, TAG_LIST).to_sql
  end
end
