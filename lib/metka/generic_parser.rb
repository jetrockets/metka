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

    def call(value)
      TagList.new.tap do |tag_list|
        case value
        when String
          value = value.to_s.dup
          gsub_quote_pattern!(tag_list, value, double_quote_pattern)
          gsub_quote_pattern!(tag_list, value, single_quote_pattern)

          tag_list.merge value.split(Regexp.new joined_delimiter).map(&:strip).reject(&:empty?)
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

    def joined_delimiter
      [Metka.config.delimiter].flatten
        .map { |delimeter| Regexp.escape(delimeter) }
        .join('|')
    end

    def single_quote_pattern
      /(\A|#{joined_delimiter})\s*'(.*?)'\s*(?=#{joined_delimiter}\s*|\z)/
    end

    def double_quote_pattern
      /(\A|#{joined_delimiter})\s*"(.*?)"\s*(?=#{joined_delimiter}\s*|\z)/
    end
  end
end
