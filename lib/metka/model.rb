# frozen_string_literal: true

require 'active_support/concern'

module Metka
  # Extends AR model with methods to use tags
  module Model
    
    extend ActiveSupport::Concern

    included do
      scope :tagged_with, -> (tags, options = {}) do
        tag_list = Metka.config.parser.instance.(tags)
        options = options.dup

        return none if tag_list.empty?

        ::Metka::QueryBuilder.new.(self, 'tags', tag_list, options)
      end

    end

    module ClassMethods # :nodoc:

    end
  end
end
