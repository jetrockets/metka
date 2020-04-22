# frozen_string_literal: true
module Metka
  TAGGED_COLUMN_NAMES = []

  def self.Model(column:, **options)
    TAGGED_COLUMN_NAMES << column unless TAGGED_COLUMN_NAMES.include?(column)
    Metka::Model.new(column: column, **options)
  end

  class Model < Module
    def initialize(column:, **options)
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

      # @param model [ActiveRecord::Base] model on which to execute search
      # @param tags [Object] list of tags, representation depends on parser used
      # @param options [Hash] options
      #   @option :join_operator ['AND', 'OR']
      # @returns ViewPost::ActiveRecord_Relation
      tagged_with_lambda = ->(model, tags, **options) {
        parsed_tag_list = parser.call(tags)
        return model.none if parsed_tag_list.empty?

        request_sql = TAGGED_COLUMN_NAMES.map do |column|
          ::Metka::QueryBuilder.new.call(model, column, parsed_tag_list, options).to_sql
        end.join(" #{options[:join_operator]} ")

        model.where(request_sql)
      }

      tagged_without = ->(model, tags, **options) {
        parsed_tag_list = parser.call(tags)

        request_sql = TAGGED_COLUMN_NAMES.map do |column|
          ::Metka::QueryBuilder.new.call(model, column, parsed_tag_list, options).to_sql
        end.join(" #{options[:join_operator]} ")

        model.where.not(request_sql)
      }

      base.class_eval do
        scope "with_all_#{column}", ->(tags) { search_by_tags.call(self, tags, column) }
        scope "with_any_#{column}", ->(tags) { search_by_tags.call(self, tags, column, {any: true}) }
        scope "without_all_#{column}", ->(tags) { search_by_tags.call(self, tags, column, {exclude_all: true, without: true}) }
        scope "without_any_#{column}", ->(tags) { search_by_tags.call(self, tags, column, {exclude_any: true, without: true}) }

        unless respond_to?(:tagged_without_all)
          scope :tagged_without_all, ->(tags = '', join_operator: 'OR') {
            tagged_without.call(self, tags, exclude_all: true, join_operator: join_operator)
          }
        end

        unless respond_to?(:tagged_without_any)
          scope :tagged_without_any, ->(tags = '', join_operator: 'OR') {
            tagged_without.call(self, tags, exclude_any: true, join_operator: join_operator)
          }
        end

        unless respond_to?(:tagged_with)
          scope :tagged_with, -> (tags = '', options = {}) {
            options[:join_operator] ||= 'OR'
            options = {any: false}.merge(options)

            if options[:exclude] && options[:any]
              options[:exclude_any] = true
            elsif options[:exclude] && !options[:any]
              options[:exclude_all] = true
            end

            tagged_with_lambda.call(self, tags, **options)
          }
        end
      end

      base.define_method(column.singularize + '_list=') do |v|
        write_attribute(column, parser.call(v).to_a)
        write_attribute(column, nil) if send(column).empty?
      end

      base.define_method(column.singularize + '_list') do
        parser.call(send(column))
      end
    end
  end
end
