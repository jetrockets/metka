# frozen_string_literal: true

module Metka
  class TagsQuery
    # PostgreSQL array operators; also the source of truth for valid match
    # modes, so an unknown mode raises KeyError on either adapter.
    OPERATORS = { all: "@>", any: "&&" }.freeze

    def initialize(match: :all)
      OPERATORS.fetch(match)
      @match = match
    end

    def call(model, column_name, tag_list)
      if model.connection.adapter_name.match?(/sqlite/i)
        sqlite(model, column_name, tag_list)
      else
        postgresql(model, column_name, tag_list)
      end
    end

    private

    # Always the operator form, even for one tag: `tag = ANY(column)` cannot
    # use a GIN index on the column, while `column @> ARRAY[tag]` can.
    def postgresql(model, column_name, tag_list)
      Arel::Nodes::InfixOperation.new(
        OPERATORS.fetch(@match),
        model.arel_table[column_name],
        literal("ARRAY[?]::varchar[]", tag_list.to_a)
      )
    end

    # SQLite has no array type or containment operators; tags live in a JSON
    # array and json_each unpacks it into rows an EXISTS can probe. There is
    # no index that can serve these predicates — SQLite tag queries are table
    # scans.
    #
    # json_each(NULL) yields no rows, so EXISTS over an untagged column is
    # FALSE rather than NULL and the exclude path needs no NULL guard here.
    def sqlite(model, column_name, tag_list)
      column = model.connection.quote_table_name("#{model.table_name}.#{column_name}")

      sql =
        if @match == :all
          tag_list.to_a.map { |tag|
            sanitize("EXISTS (SELECT 1 FROM json_each(#{column}) WHERE value = ?)", tag)
          }.join(" AND ")
        else
          sanitize("EXISTS (SELECT 1 FROM json_each(#{column}) WHERE value IN (?))", tag_list.to_a)
        end

      # Grouping keeps the AND-joined predicates one node, so the query
      # builder can OR and negate it like the PostgreSQL operator form.
      Arel::Nodes::Grouping.new(Arel::Nodes::SqlLiteral.new(sql))
    end

    def sanitize(template, value)
      ActiveRecord::Base.sanitize_sql_for_conditions([ template, value ])
    end

    def literal(template, value)
      Arel::Nodes::SqlLiteral.new(sanitize(template, value))
    end
  end
end
