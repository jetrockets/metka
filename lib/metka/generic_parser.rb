# frozen_string_literal: true

require "singleton"

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
      @single_quote_pattern = {}
      @double_quote_pattern = {}
    end

    def call(value)
      TagList.new.tap do |tag_list|
        case value
        when String
          unquoted = value.dup

          tag_list.merge extract_quoted!(unquoted, double_quote_pattern)
          tag_list.merge extract_quoted!(unquoted, single_quote_pattern)
          tag_list.merge unquoted.split(Regexp.new(delimiter)).map(&:strip).reject(&:empty?)
        when Enumerable
          tag_list.merge value.reject(&:empty?)
        end
      end
    end

    private

    # Returns the quoted tags and strips them out of +text+, which is left
    # holding only the unquoted remainder for the delimiter split to handle.
    def extract_quoted!(text, pattern)
      tags = []
      text.gsub!(pattern) { tags << Regexp.last_match[:tag]; "" }
      tags
    end

    def delimiter
      Metka.delimiter
    end

    def single_quote_pattern
      @single_quote_pattern[delimiter] ||= /(?:\A|#{delimiter})\s*'(?<tag>.*?)'\s*(?=#{delimiter}\s*|\z)/
    end

    def double_quote_pattern
      @double_quote_pattern[delimiter] ||= /(?:\A|#{delimiter})\s*"(?<tag>.*?)"\s*(?=#{delimiter}\s*|\z)/
    end
  end
end
