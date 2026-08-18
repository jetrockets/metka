# frozen_string_literal: true

require "set"

module Metka
  # The parsed form of a tag string: an ordered, de-duplicated set of tags.
  #
  #   Metka::GenericParser.instance.call("ruby, rails, ruby").to_s
  #   #=> "ruby, rails"
  class TagList < Set
    # Set#to_s is an alias of #inspect, so a tag list rendered itself as
    # "#<Set: {\"ruby\"}>". This is a user-facing value, so render it the way
    # it was written.
    #
    # Joins on the configured delimiter, so it round-trips through the parser.
    # A parser subclass that overrides #delimiter privately — as the dummy
    # app's CustomParser does — is not visible from here, so a tag list it
    # produced renders with the configured delimiter rather than that parser's.
    def to_s
      to_a.join("#{Metka.delimiter} ")
    end
  end
end
