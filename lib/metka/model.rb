# frozen_string_literal: true

module Metka
  def self.Model(column:, **options)
    Metka::Model.new(column: column, **options)
  end

  class Model < Module
    def initialize(column: , **options)
      @column = column
      @options = options
    end

    def included(base)
      column = @column
      parser = ->(tags) {
        @options[:parser] ? @options[:parser].call(tags) : Metka.config.parser.instance.call(tags)
      }

      search_by_tags = ->(model, tags, column, **options) {
        parsed_tag_list = parser.call(tags)
        if options[:without].present?
          model.where.not(::Metka::QueryBuilder.new.call(model, column, parsed_tag_list, options))
        else
          return model.none if parsed_tag_list.empty?
          model.where(::Metka::QueryBuilder.new.call(model, column, parsed_tag_list, options))
        end
      }

      base.class_eval do
        scope "with_all_#{column}", ->(tags) { search_by_tags.call(self, tags, column) }
        scope "with_any_#{column}", ->(tags) { search_by_tags.call(self, tags, column, { any: true }) }
        scope "without_all_#{column}", ->(tags) { search_by_tags.call(self, tags, column, { exclude_all: true, without: true }) }
        scope "without_any_#{column}", ->(tags) { search_by_tags.call(self, tags, column, { exclude_any: true, without: true }) }
      end

      base.define_method(column.singularize + '_list=') do |v|
        self.write_attribute(column, parser.call(v).to_a)
        self.write_attribute(column, nil) if self.send(column).empty?
      end

      base.define_method(column.singularize + '_list') do
        parser.call(self.send(column))
      end
    end
  end
end