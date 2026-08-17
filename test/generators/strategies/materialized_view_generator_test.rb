# frozen_string_literal: true

require 'test_helper'
require 'rails/generators/test_case'
require 'generators/metka/strategies/materialized_view/materialized_view_generator'

class MaterializedViewGeneratorTest < Rails::Generators::TestCase
  MIGRATION = 'db/migrate/create_tagged_notes_materialized_view.rb'

  tests Metka::Generators::Strategies::MaterializedViewGenerator
  destination File.expand_path('../../tmp', __dir__)

  setup do
    prepare_destination
    run_generator ['--source-table-name=notes']
  end

  test 'creates migration' do
    assert_migration MIGRATION
  end

  test 'up migration creates function' do
    assert_migration MIGRATION, /CREATE OR REPLACE FUNCTION metka_refresh_tagged_notes_materialized_view/i
  end

  test 'up migration creates materialized view' do
    assert_migration MIGRATION, /CREATE MATERIALIZED VIEW tagged_notes/i
  end

  test 'up migration creates uniq index' do
    assert_migration MIGRATION, /CREATE UNIQUE INDEX/i
  end

  test 'up migration creates trigger' do
    assert_migration MIGRATION, /CREATE TRIGGER metka_on_notes/i
  end

  test 'down migration drops trigger' do
    assert_migration MIGRATION, /DROP TRIGGER IF EXISTS/i
  end

  test 'down migration drops function' do
    assert_migration MIGRATION, /DROP FUNCTION IF EXISTS/i
  end

  test 'down migration drops materialized view' do
    assert_migration MIGRATION, /DROP MATERIALIZED VIEW IF EXISTS/i
  end
end
