# frozen_string_literal: true

require "test_helper"

class MetkaQueryBuilderTest < ActiveSupport::TestCase
  test "combines the tag columns with OR by default" do
    assert_equal 2, Post.tagged_with(%w[ruby]).count
  end

  test "accepts the Metka join operators" do
    assert_equal 2, Post.tagged_with(%w[ruby], join_operator: Metka::OR).count
    assert_equal 1, Post.tagged_with(%w[ruby], join_operator: Metka::AND).count
  end

  test "accepts bare symbols" do
    assert_equal 2, Post.tagged_with(%w[ruby], join_operator: :or).count
    assert_equal 1, Post.tagged_with(%w[ruby], join_operator: :and).count
  end

  # Metka::AND and Metka::OR were these Arel classes until they became symbols.
  test "still accepts the Arel node classes it used to expose" do
    assert_equal 2, Post.tagged_with(%w[ruby], join_operator: Arel::Nodes::Or).count
    assert_equal 1, Post.tagged_with(%w[ruby], join_operator: Arel::Nodes::And).count
  end

  # An unrecognised operator used to fall through to nil, and where(nil)
  # matches every row — so a typo silently returned the whole table.
  test "raises on an unrecognised join operator rather than matching everything" do
    [ :bogus, "OR", "and", 1 ].each do |operator|
      error = assert_raises(ArgumentError) { Post.tagged_with(%w[ruby], join_operator: operator).count }
      assert_match(/Unknown join_operator/, error.message)
    end
  end

  test "raises when :on leaves no columns to search" do
    error = assert_raises(ArgumentError) { Post.tagged_with(%w[ruby], on: []).count }
    assert_match(/No tag columns/, error.message)
  end
end
