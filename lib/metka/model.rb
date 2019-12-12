# frozen_string_literal: true

require 'active_support/concern'

module Metka
  def self.Model(column:, **options)
    Metka::Model.new(column: column, **options)
  end

  class Model < Module
    extend ActiveSupport::Concern

    def initialize(column: , **options)
      @column = column
      @options = options
    end

    def included(base)
      column = @column

      base.class_eval do
        scope "with_all_#{column}", ->(tags) {
          return none if tag_list(tags).empty?
          self.where(::Metka::QueryBuilder.new.call(self, column, tag_list(tags), {}))
        }

        scope "with_any_#{column}", ->(tags) {
          return none if tag_list(tags).empty?
          self.where(::Metka::QueryBuilder.new.call(self, column, tag_list(tags), { any: true }))
        }

        scope "without_all_#{column}", ->(tags) {
          self.where.not(::Metka::QueryBuilder.new.call(self, column, tag_list(tags), { exclude_all: true }))
        }

        scope "without_any_#{column}", ->(tags) {
          self.where.not(::Metka::QueryBuilder.new.call(self, column, tag_list(tags), { exclude_any: true }))
        }
      end

      base.instance_eval do
        private

        def tag_list(tags)
          Metka.config.parser.instance.call(tags)
        end
      end

      base.define_method(column.singularize + '_list=') do |v|
        self.write_attribute(column, Metka.config.parser.instance.call(v).to_a)
        self.write_attribute(column, nil) if self.send(column).empty?
      end

      base.define_method(column.singularize + '_list') do
        Metka.config.parser.instance.call(self.send(column))
      end
    end
  end
end