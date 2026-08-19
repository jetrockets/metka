# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"
require_relative "../../sql_identifier"

module Metka
  module Generators
    module Strategies
      class TableGenerator < ::Rails::Generators::Base # :nodoc:
        include Rails::Generators::Migration
        include Metka::Generators::SqlIdentifier

        DEFAULT_SOURCE_COLUMNS = [ "tags" ].freeze

        desc <<~LONGDESC
          Generates migration to implement table strategy for Metka

          > $ rails g metka:strategies:table \
          --source-table-name=NAME_OF_TABLE_WITH_TAGS \
          --source-columns=NAME_OF_TAGGED_COLUMN_1 NAME_OF_TAGGED_COLUMN_2 \
          --table-name=NAME_OF_TABLE
        LONGDESC

        source_root File.expand_path("templates", __dir__)

        class_option :source_table_name, type: :string, required: true,
          desc: "Name of the table that has a column with tags"

        class_option :source_columns, type: :array, default: DEFAULT_SOURCE_COLUMNS,
          desc: "List of the tagged columns names"

        class_option :table_name, type: :string,
          desc: "Custom name for the resulting table"

        def generate_migration
          validate_sql_identifiers!(
            "--source-table-name" => [ source_table_name ],
            "--source-columns" => source_columns,
            "--table-name" => Array(options[:table_name])
          )

          migration_template migration_template_file, "db/migrate/#{migration_name}.rb"
        end

        no_tasks do
          # The migration is written for the database the app is connected to
          # at generation time: transition-table triggers for PostgreSQL,
          # per-row json_each triggers for SQLite.
          def migration_template_file
            if ::ActiveRecord::Base.connection.adapter_name.match?(/sqlite/i)
              "migration.sqlite.rb.erb"
            else
              "migration.rb.erb"
            end
          end

          def source_table_name
            options[:source_table_name]
          end

          def source_columns
            options[:source_columns]
          end

          def source_columns_names
            source_columns.join("_and_")
          end

          def table_name
            return options[:table_name] if options[:table_name]

            "#{source_table_name}_#{source_columns_names}_cloud"
          end

          def migration_name
            "create_#{table_name}_table"
          end

          def migration_class_name
            migration_name.classify
          end
        end

        def self.next_migration_number(dir)
          ::ActiveRecord::Generators::Base.next_migration_number(dir)
        end
      end
    end
  end
end
