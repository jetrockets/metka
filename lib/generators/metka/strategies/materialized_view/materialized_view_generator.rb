# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/active_record'

module Metka
  module Generators
    module Strategies
      class MaterializedViewGenerator < ::Rails::Generators::Base # :nodoc:
        include Rails::Generators::Migration

        DEFAULT_SOURCE_COLUMNS = ['tags'].freeze

        desc <<~LONGDESC
          Generates migration to implement view strategy for Metka

          > $ rails g metka:strategies:materialized_view \
          --source-table-name=NAME_OF_TABLE_WITH_TAGS \
          --source-columns=NAME_OF_TAGGED_COLUMN_1 NAME_OF_TAGGED_COLUMN_2 \
          --view-name=NAME_OF_VIEW
        LONGDESC

        source_root File.expand_path('templates', __dir__)

        class_option :source_table_name, type: :string, required: true,
                                         desc: 'Name of the table that has a column with tags'

        class_option :source_columns, type: :array, default: DEFAULT_SOURCE_COLUMNS,
                                      desc: 'List of the tagged columns names'

        class_option :view_name, type: :string,
                                 desc: 'Custom name for the resulting view'

        def generate_migration
          migration_template 'migration.rb.erb', "db/migrate/#{migration_name}.rb"
        end

        no_tasks do
          def source_table_name
            options[:source_table_name]
          end

          def source_columns
            options[:source_columns]
          end

          def source_columns_names
            source_columns.join('_and_')
          end

          def view_name
            return options[:view_name] if options[:view_name]

            columns_sequence = source_columns == DEFAULT_SOURCE_COLUMNS ? nil : "_with_#{source_columns_names}"
            "tagged#{columns_sequence}_#{source_table_name}"
          end

          def migration_name
            "create_#{view_name}_materialized_view"
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
