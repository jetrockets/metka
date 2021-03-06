# frozen_string_literal: true

require 'singleton'

module Metka
  ##
  # Returns a new Metka::TagList using the given tag string.
  #
  # Example:
  # tag_list = Metka::GenericParser.instance.("One , Two, Three")
  # tag_list # ["One", "Two", "Three"]
  class GenericParser
    include Singleton

    def initialize
      @single_quote_pattern ||= {}
      @double_quote_pattern ||= {}
    end

    def call(value)
      TagList.new.tap do |tag_list|
        case value
        when String
          value = value.to_s.dup
          gsub_quote_pattern!(tag_list, value, double_quote_pattern)
          gsub_quote_pattern!(tag_list, value, single_quote_pattern)

          tag_list.merge value.split(Regexp.new(delimiter)).map(&:strip).reject(&:empty?)
        when Enumerable
          tag_list.merge value.reject(&:empty?)
        end
      end
    end

    private

    def gsub_quote_pattern!(tag_list, value, pattern)
      value.gsub!(pattern) {
        tag_list.add(Regexp.last_match[2])
        ''
      }
    end

    def delimiter
      Metka.delimiter
    end

    def single_quote_pattern
      @single_quote_pattern[delimiter] ||= /(\A|#{delimiter})\s*'(.*?)'\s*(?=#{delimiter}\s*|\z)/
    end

    def double_quote_pattern
      @double_quote_pattern[delimiter] ||= /(\A|#{delimiter})\s*"(.*?)"\s*(?=#{delimiter}\s*|\z)/
    end
  end
end
