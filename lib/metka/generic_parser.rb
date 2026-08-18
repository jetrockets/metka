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
      @separator = {}
      @single_quote_pattern = {}
      @double_quote_pattern = {}
    end

    def call(value)
      # A TagList is this parser's own output, so it is already split,
      # stripped, and de-duplicated — hand it back rather than rebuilding it.
      return value if value.is_a?(TagList)

      TagList.new.tap do |tag_list|
        case value
        when String
          unquoted = value.dup

          tag_list.merge extract_quoted!(unquoted, double_quote_pattern)
          tag_list.merge extract_quoted!(unquoted, single_quote_pattern)
          tag_list.merge unquoted.split(separator).map(&:strip).reject(&:empty?)
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

    # The delimiter is a literal separator, so it is escaped before going
    # anywhere near a Regexp. Without this a delimiter of "|" becomes an empty
    # alternation matching between every character, and "." matches every
    # character — both silently shredding the input instead of splitting it.
    def separator
      @separator[delimiter] ||= Regexp.new(Regexp.escape(delimiter))
    end

    def single_quote_pattern
      @single_quote_pattern[delimiter] ||= /(?:\A|#{Regexp.escape(delimiter)})\s*'(?<tag>.*?)'\s*(?=#{Regexp.escape(delimiter)}\s*|\z)/
    end

    def double_quote_pattern
      @double_quote_pattern[delimiter] ||= /(?:\A|#{Regexp.escape(delimiter)})\s*"(?<tag>.*?)"\s*(?=#{Regexp.escape(delimiter)}\s*|\z)/
    end
  end
end
