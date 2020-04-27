# frozen_string_literal: true
require 'pry'

require 'arel'
require_relative 'query_builder/base_query'
require_relative 'query_builder/any_tags_query'
require_relative 'query_builder/all_tags_query'

module Metka
  class QueryBuilder
    def call(model, columns, tags, options)
      strategy = options_to_strategy(options)

      query = case columns
              when String, Symbol
                build_query(strategy).(model, columns, tags)
              when Enumerable
                join(options[:join_operator]) do
                  columns.map do |column|
                    build_query(strategy).(model, column, tags)
                  end
                end
              end

      if options[:exclude].present?
        Arel::Nodes::Not.new(query)
      else
        query
      end
    end

    private

    def options_to_strategy options
      if options[:any].present?
        AnyTagsQuery
      else
        AllTagsQuery
      end
    end

    def join(operator, &block)
      if operator == ::Metka::AND
        join_and(block.call)
      elsif operator == ::Metka::OR
        join_or(block.call)
      end
    end

    # @param queries [Array<Arel::Node>, Arel::Node]
    # @return [Arel::Node]
    def join_or(queries)
      case queries
      when ::Arel::Node
        queries
      when Array
        l, *r = queries
        return l if r.empty?

        l.or(join_or(r))
      end
    end

    def join_and(queries)
      case queries
      when Arel::Node
        queries
      when Array
        l, *r = queries
        return l if r.empty?

        l.and(join_and(r))
      end
    end

    def build_query(strategy)
      @build_query ||= ->(model, column, tags) { strategy.instance.call(model, column, tags) }.curry
    end
  end
end
