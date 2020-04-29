# frozen_string_literal: true

require 'arel'

module Metka
  OR = Arel::Nodes::Or
  AND = Arel::Nodes::And

  def self.Model(column: nil, columns: nil, **options)
    columns = [column, *columns].uniq.compact
    raise ArgumentError, 'Columns not specified' unless columns.present?

    Metka::Model.new(column: column, columns: columns, **options)
  end

  class Model < Module
    def initialize(columns: nil, **options)
      @columns = columns.dup.freeze
      @options = options.dup.freeze
    end

    def included(base)
      columns = @columns
      parser = ->(tags) {
        @options[:parser] ? @options[:parser].call(tags) : Metka.config.parser.instance.call(tags)
      }

      search_by_tags = ->(model, tags, column, **options) {
        parsed_tag_list = parser.call(tags)
        return model.none if parsed_tag_list.empty?

        model.where(::Metka::QueryBuilder.new.call(model, column, parsed_tag_list, options))
      }

      # @param model [ActiveRecord::Base] model on which to execute search
      # @param tags [Object] list of tags, representation depends on parser used
      # @param options [Hash] options
      #   @option :join_operator [Metka::AND, Metka::OR]
      # @returns ViewPost::ActiveRecord_Relation
      tagged_with_lambda = ->(model, tags, **options) {
        parsed_tag_list = parser.call(tags)

        return model.none if parsed_tag_list.empty?

        request = ::Metka::QueryBuilder.new.call(model, columns, parsed_tag_list, options)
        model.where(request)
      }

      base.class_eval do
        columns.each do |column|
          scope "with_all_#{column}", ->(tags) { search_by_tags.call(self, tags, column) }
          scope "with_any_#{column}", ->(tags) { search_by_tags.call(self, tags, column, {any: true}) }
          scope "without_all_#{column}", ->(tags) { search_by_tags.call(self, tags, column, {exclude: true}) }
          scope "without_any_#{column}", ->(tags) { search_by_tags.call(self, tags, column, {any: true, exclude: true}) }
        end

        unless respond_to?(:tagged_with)
          scope :tagged_with, ->(tags = '', options = {}) {
            options[:join_operator] ||= ::Metka::OR
            options = {any: false}.merge(options)

            tagged_with_lambda.call(self, tags, **options)
          }
        end
      end

      columns.each do |column|
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
end
