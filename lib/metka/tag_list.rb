# frozen_string_literal: true

require 'set'

module Metka
  class TagList < Set
    # def add(o)
    #   if o.respond_to?(:each)
    #     o.each { |e| Metka.config.parser.call(e) }
    #   else
    #     super(Metka.config.parser.call(o))
    #   end
    # end
  end
end