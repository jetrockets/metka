# frozen_string_literal: true

require "test_helper"

class MetkaBaseQueryTest < ActiveSupport::TestCase
  MODEL = Post
  COLUMN_NAME = "tags"
  TAG_LIST = [ "ruby" ].freeze

  setup do
    @query = Metka::BaseQuery.instance
  end

  test "responds to .call" do
    assert_respond_to @query, :call
  end

  test "returns Arel::Nodes::Equality object" do
    assert_instance_of Arel::Nodes::Equality, @query.call(MODEL, COLUMN_NAME, TAG_LIST)
  end

  test "returns correct sql" do
    assert_equal %('ruby' = ANY("posts"."tags")), @query.call(MODEL, COLUMN_NAME, TAG_LIST).to_sql
  end
end
