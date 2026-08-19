# frozen_string_literal: true

module Metka
  module Generators
    # Generator options land verbatim in the migration's SQL, so they are
    # constrained to plain identifiers: a hostile-looking name fails closed
    # instead of producing broken or surprising DDL.
    module SqlIdentifier
      IDENTIFIER = /\A[a-zA-Z_][a-zA-Z0-9_]*\z/

      private

      def validate_sql_identifiers!(names_by_option)
        names_by_option.each do |option, names|
          names.each do |name|
            next if IDENTIFIER.match?(name)

            raise Thor::Error, "#{option} #{name.inspect} must be a plain SQL identifier: " \
              "letters, digits and underscores, not starting with a digit"
          end
        end
      end
    end
  end
end
