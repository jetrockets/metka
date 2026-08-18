# frozen_string_literal: true

module Metka
  class TagsQuery
    OPERATORS = { all: "@>", any: "&&" }.freeze

    def initialize(match: :all)
      @operator = OPERATORS.fetch(match)
    end

    # Always the operator form, even for one tag: `tag = ANY(column)` cannot
    # use a GIN index on the column, while `column @> ARRAY[tag]` can.
    def call(model, column_name, tag_list)
      Arel::Nodes::InfixOperation.new(
        @operator,
        model.arel_table[column_name],
        literal("ARRAY[?]::varchar[]", tag_list.to_a)
      )
    end

    private

    def literal(template, value)
      Arel::Nodes::SqlLiteral.new(
        ActiveRecord::Base.sanitize_sql_for_conditions([ template, value ])
      )
    end
  end
end
