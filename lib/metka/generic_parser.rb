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
        tag_list.merge value.split(',').map(&:strip).reject(&:empty?)
      end
    end
  end
end