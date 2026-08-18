# frozen_string_literal: true

require "set"

module Metka
  # The parsed form of a tag string: an ordered, de-duplicated set of tags.
  #
  #   Metka::GenericParser.instance.call("ruby, rails, ruby").to_s
  #   #=> "ruby, rails"
  class TagList < Set
    SEPARATOR = ", "

    # Set#to_s is an alias of #inspect, so a tag list rendered itself as
    # "#<Set: {\"ruby\"}>". This is a user-facing value, so render it the way
    # it was written instead.
    #
    # Joining on Metka.delimiter would look tempting and be wrong: the
    # delimiter is interpolated into a Regexp, so it holds a pattern rather
    # than a separator — CustomParser's is the escaped '\|'.
    def to_s
      to_a.join(SEPARATOR)
    end
  end
end
