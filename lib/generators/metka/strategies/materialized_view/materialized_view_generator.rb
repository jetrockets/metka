# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/active_record'

module Metka
  module Generators
    module Strategies
      class MaterializedViewGenerator < ::Rails::Generators::Base # :nodoc:
        include Rails::Generators::Migration

        desc <<~LONGDESC
          Generates migration to implement view strategy for Metka

          > $ rails g metka:strategies:materialized_view --source-table-name=NAME_OF_TABLE_WITH_TAGS
        LONGDESC

        source_root File.expand_path('templates', __dir__)

        class_option :source_table_name, type: :string, required: true,
                                         desc: 'Name of the table that has a column with tags'

        class_option :source_column_name, type: :string, default: 'tags',
                                          desc: 'Name of the column with stored tags'

        def generate_migration
          migration_template 'migration.rb.erb', "db/migrate/#{migration_name}.rb"
        end

        no_tasks do
          def source_table_name
            options[:source_table_name]
          end

          def source_column_name
            options[:source_column_name]
          end

          def view_name
            "tagged_#{source_table_name}"
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
