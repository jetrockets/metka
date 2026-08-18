# frozen_string_literal: true

require "test_helper"

class MetkaTagListTest < ActiveSupport::TestCase
  test "renders itself as the tag string it was parsed from" do
    assert_equal "ruby, rails", Metka::TagList.new([ "ruby", "rails" ]).to_s
  end

  test "renders an empty list as an empty string" do
    assert_equal "", Metka::TagList.new.to_s
  end

  test "keeps the order tags were added in" do
    assert_equal "rails, ruby", Metka::TagList.new([ "rails", "ruby" ]).to_s
  end

  test "drops duplicates" do
    assert_equal "ruby, rails", Metka::TagList.new([ "ruby", "rails", "ruby" ]).to_s
  end

  test "round-trips a parsed tag string" do
    assert_equal "ruby, rails", Metka::GenericParser.instance.call("ruby, rails").to_s
  end

  test "is what the parser and the list accessors return" do
    assert_instance_of Metka::TagList, Metka::GenericParser.instance.call("ruby")
    assert_instance_of Metka::TagList, posts(:ruby_post).tag_list
  end
end
