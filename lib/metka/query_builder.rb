# frozen_string_literal: true

require "arel"
require_relative "tags_query"

module Metka
  class QueryBuilder
    # Stateless, so one frozen instance serves every tagged_with call.
    def self.instance
      @instance ||= new.freeze
    end

    STRATEGIES = {
      all: TagsQuery.new(match: :all).freeze,
      any: TagsQuery.new(match: :any).freeze
    }.freeze

    JOINERS = {
      and: ->(nodes) { Arel::Nodes::And.new(nodes) },
      or: ->(nodes) { nodes.reduce(:or) }
    }.freeze

    # Metka::AND and Metka::OR used to be these Arel classes. Callers that
    # passed them literally still work.
    LEGACY_OPERATORS = {
      Arel::Nodes::And => :and,
      Arel::Nodes::Or => :or
    }.freeze

    def call(model, columns, tags, options)
      strategy = STRATEGIES.fetch(options[:any].present? ? :any : :all)
      nodes = columns.map { |column| strategy.call(model, column, tags) }
      query = join(nodes, using: options[:join_operator])

      options[:exclude].present? ? exclude(query) : query
    end

    private

    def join(nodes, using:)
      raise ArgumentError, "No tag columns to search" if nodes.empty?

      JOINERS.fetch(normalize(using)) {
        raise ArgumentError,
          "Unknown join_operator #{using.inspect}, expected #{JOINERS.keys.map(&:inspect).join(" or ")}"
      }.call(nodes)
    end

    def normalize(operator)
      LEGACY_OPERATORS.fetch(operator, operator)
    end

    # A NULL tag column makes its comparison NULL, and NOT NULL is NULL, so the
    # row silently drops out of the WHERE entirely. Coalescing to FALSE first
    # reads a NULL column as "this row does not carry the tag", which is what
    # excluding actually asks.
    #
    # Only the exclude path is wrapped. Coalescing the columns themselves would
    # fix it too, but costs the GIN index on every positive query.
    def exclude(query)
      Arel::Nodes::Not.new(
        Arel::Nodes::NamedFunction.new("COALESCE", [ query, Arel.sql("FALSE") ])
      )
    end
  end
end
