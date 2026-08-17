# frozen_string_literal: true

require 'test_helper'

class MetkaGenericParserTest < ActiveSupport::TestCase
  setup do
    @parser = Metka::GenericParser.instance
    @delimiter = Metka.config.delimiter
  end

  teardown do
    Metka.config.delimiter = @delimiter
  end

  test 'returns empty array if empty tag is passed' do
    ['', ' ', nil, []].each do |tag|
      assert_empty @parser.call(tag)
    end
  end

  test 'separates tags by comma' do
    assert_equal %w[cool data I have], @parser.call('cool,data,,I,have').to_a
  end

  test 'works with utf8 delimiter' do
    Metka.config.delimiter = '的'

    assert_equal %w[我 东西可能是不见了，还好有备份], @parser.call('我的东西可能是不见了，还好有备份').to_a
  end

  test 'escapes single quote' do
    assert_equal ['I, have', 'code'], @parser.call("'I, have', code").to_a
  end
end
