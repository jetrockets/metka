# frozen_string_literal: true

require "singleton"

module Metka
  class AnyTagsQuery
    include Singleton

    def call(model, column_name, tag_list)
      column_cast = Arel::Nodes::NamedFunction.new(
        "CAST",
        [model.arel_table[column_name].as("text[]")]
      )

      value = Arel::Nodes::SqlLiteral.new(
        # In Rails 5.2 and above Sanitanization moved to public level, but still we have to support 4.2 and 5.0 and 5.1
        ActiveRecord::Base.send(:sanitize_sql_for_conditions, ["ARRAY[?]", tag_list.to_a])
      )

      value_cast = Arel::Nodes::NamedFunction.new(
        "CAST",
        [value.as("text[]")]
      )

      Arel::Nodes::InfixOperation.new("&&", column_cast, value_cast)
    end
  end
end
