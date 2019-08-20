# frozen_string_literal: true

module Metka
  class AnyTagsQuery
    def call(model, column_name, tag_list)
      column_cast = Arel::Nodes::NamedFunction.new(
        'CAST',
        [model.arel_table[column_name].as("text[]")]
      )

      value = Arel::Nodes::SqlLiteral.new(
        sanitize_sql_array(["ARRAY[?]", tag_columns_sanitize_list(tag_list)])
      )

      value_cast = Arel::Nodes::NamedFunction.new(
        'CAST',
        [value.as("text[]")]
      )

      where(Arel::Nodes::InfixOperation.new("&&", column_cast, value_cast))
    end
  end
end