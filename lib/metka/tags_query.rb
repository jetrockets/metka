# frozen_string_literal: true

module Metka
  class TagsQuery
    OPERATORS = { all: "@>", any: "&&" }.freeze

    def initialize(match: :all)
      @operator = OPERATORS.fetch(match)
    end

    def call(model, column_name, tag_list)
      tags = tag_list.to_a

      if tags.one?
        tagged_with_one(model, column_name, tags.first)
      else
        tagged_with_many(model, column_name, tags)
      end
    end

    private

    # A single tag matches identically under either operator, so ANY covers both.
    def tagged_with_one(model, column_name, tag)
      Arel::Nodes::Equality.new(
        literal("?", tag),
        Arel::Nodes::NamedFunction.new("ANY", [ model.arel_table[column_name] ])
      )
    end

    def tagged_with_many(model, column_name, tags)
      Arel::Nodes::InfixOperation.new(
        @operator,
        model.arel_table[column_name],
        literal("ARRAY[?]::varchar[]", tags)
      )
    end

    def literal(template, value)
      Arel::Nodes::SqlLiteral.new(
        ActiveRecord::Base.sanitize_sql_for_conditions([ template, value ])
      )
    end
  end
end
