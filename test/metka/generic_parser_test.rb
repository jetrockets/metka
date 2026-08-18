# frozen_string_literal: true

require "test_helper"

class MetkaGenericParserTest < ActiveSupport::TestCase
  setup do
    @parser = Metka::GenericParser.instance
    @delimiter = Metka.config.delimiter
  end

  teardown do
    Metka.config.delimiter = @delimiter
  end

  test "returns empty array if empty tag is passed" do
    [ "", " ", nil, [] ].each do |tag|
      assert_empty @parser.call(tag)
    end
  end

  test "separates tags by comma" do
    assert_equal %w[cool data I have], @parser.call("cool,data,,I,have").to_a
  end

  test "works with utf8 delimiter" do
    Metka.config.delimiter = "\u7684"

    assert_equal %w[我 东西可能是不见了，还好有备份], @parser.call("\u6211\u7684\u4E1C\u897F\u53EF\u80FD\u662F\u4E0D\u89C1\u4E86\uFF0C\u8FD8\u597D\u6709\u5907\u4EFD").to_a
  end

  test "escapes single quote" do
    assert_equal [ "I, have", "code" ], @parser.call("'I, have', code").to_a
  end

  test "escapes double quote" do
    assert_equal [ "I, have", "code" ], @parser.call(%q("I, have", code)).to_a
  end

  test "handles single and double quoted tags in one string" do
    assert_equal [ "double", "single" ], @parser.call(%q('single' , "double")).to_a
  end

  test "keeps a quoted tag that contains the delimiter as one tag" do
    assert_equal [ "a,b", "c" ], @parser.call(%q('a,b', c)).to_a
  end

  test "leaves the unquoted remainder to the delimiter split" do
    assert_equal [ "quoted", "one", "two" ], @parser.call(%q('quoted', one, two)).to_a
  end
end
