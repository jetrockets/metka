# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"
require_relative "../../sql_identifier"

module Metka
  module Generators
    module Strategies
      class IndexGenerator < ::Rails::Generators::Base # :nodoc:
        include Rails::Generators::Migration
        include Metka::Generators::SqlIdentifier

        DEFAULT_SOURCE_COLUMNS = [ "tags" ].freeze

        desc <<~LONGDESC
          Generates a migration implementing the SQLite index strategy for
          Metka: one (tag_name, record_id) side table per tagged column,
          maintained by triggers, so tag queries become index seeks instead
          of json_each table scans. Declare the tables on the model with the
          index_tables option to route queries through them.

          PostgreSQL needs no index strategy — GIN indexes on the array
          columns already serve tag queries — so the generator produces
          nothing there.

          > $ rails g metka:strategies:index \
          --source-table-name=NAME_OF_TABLE_WITH_TAGS \
          --source-columns=NAME_OF_TAGGED_COLUMN_1 NAME_OF_TAGGED_COLUMN_2
        LONGDESC

        source_root File.expand_path("templates", __dir__)

        class_option :source_table_name, type: :string, required: true,
          desc: "Name of the table that has a column with tags"

        class_option :source_columns, type: :array, default: DEFAULT_SOURCE_COLUMNS,
          desc: "List of the tagged columns names"

        def generate_migration
          validate_sql_identifiers!(
            "--source-table-name" => [ source_table_name ],
            "--source-columns" => source_columns
          )

          unless sqlite?
            say_status :skipped,
              "the index strategy targets SQLite; PostgreSQL GIN indexes already serve tag queries",
              :yellow
            return
          end

          migration_template "migration.rb.erb", "db/migrate/#{migration_name}.rb"
        end

        no_tasks do
          def sqlite?
            ::ActiveRecord::Base.connection.adapter_name.match?(/sqlite/i)
          end

          def source_table_name
            options[:source_table_name]
          end

          def source_columns
            options[:source_columns]
          end

          def index_table_for(column)
            "#{source_table_name}_#{column}_index"
          end

          def migration_name
            "create_#{source_table_name}_#{source_columns.join('_and_')}_index_tables"
          end
        end

        def self.next_migration_number(dir)
          ::ActiveRecord::Generators::Base.next_migration_number(dir)
        end
      end
    end
  end
end
