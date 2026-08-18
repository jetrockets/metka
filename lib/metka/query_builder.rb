# frozen_string_literal: true

require "arel"
require_relative "tags_query"

module Metka
  class QueryBuilder
    def call(model, columns, tags, options)
      strategy = TagsQuery.new(match: options[:any].present? ? :any : :all)

      query =
        join(options[:join_operator]) {
          columns.map do |column|
            strategy.call(model, column, tags)
          end
        }

      if options[:exclude].present?
        Arel::Nodes::Not.new(query)
      else
        query
      end
    end

    private

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
  end
end
