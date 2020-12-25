# frozen_string_literal: true

require 'arel'
require_relative 'query_builder/base_query'
require_relative 'query_builder/any_tags_query'
require_relative 'query_builder/all_tags_query'

module Metka
  class QueryBuilder
    def call(model, columns, tags, options)
      strategy = options_to_strategy(options)

      query = join(options[:join_operator]) {
        columns.map do |column|
          build_query(strategy, model, column, tags)
        end
      }

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
      nodes = block.call

      if operator == ::Metka::AND
        join_and(nodes)
      elsif operator == ::Metka::OR
        join_or(nodes)
      end
    end

    # @param nodes [Array<Arel::Nodes::Node>, Arel::Nodes::Node]
    # @return [Arel::Nodes::Node]
    def join_or(nodes)
      node_base_klass = defined?(::Arel::Nodes::Node) ? ::Arel::Nodes::Node : ::Arel::Node

      case nodes
      when node_base_klass
        nodes
      when Array
        l, *r = nodes
        return l if r.empty?

        l.or(join_or(r))
      end
    end

    def join_and(queries)
      Arel::Nodes::And.new(queries)
    end

    def build_query(strategy, model, column, tags)
      strategy.instance.call(model, column, tags)
    end
  end
end
