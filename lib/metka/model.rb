# frozen_string_literal: true

require "active_support/concern"

module Metka
  # Extends AR model with methods to use tags
  module Model
    extend ActiveSupport::Concern

    included do
      scope :tagged_with, ->(tags, options = {}) do
        tag_list = Metka.config.parser.instance.call(tags)
        options = options.dup

        return none if tag_list.empty?

        where(::Metka::QueryBuilder.new.call(self, "tags", tag_list, options))
      end
    end

    def tag_list=(v)
      self.tags = Metka.config.parser.instance.call(v).to_a
      self.tags = nil if tags.empty?
    end

    def tag_list
      Metka.config.parser.instance.call(tags)
    end

    module ClassMethods # :nodoc:
    end
  end
end
