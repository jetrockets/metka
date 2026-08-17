# frozen_string_literal: true

require "singleton"

module Metka
  class BaseQuery
    include Singleton

    def call(model, column_name, tag_list)
      tags = tag_list.to_a

      if tags.one?
        value = Arel::Nodes::SqlLiteral.new(
          ActiveRecord::Base.sanitize_sql_for_conditions([ "?", tags.first ])
        )

        column_cast = Arel::Nodes::NamedFunction.new(
          "ANY",
          [ model.arel_table[column_name] ]
        )

        Arel::Nodes::Equality.new(value, column_cast)
      else
        value = Arel::Nodes::SqlLiteral.new(
          ActiveRecord::Base.sanitize_sql_for_conditions([ "ARRAY[?]::varchar[]", tags ])
        )

        Arel::Nodes::InfixOperation.new(infix_operator, model.arel_table[column_name], value)
      end
    end
  end
end
