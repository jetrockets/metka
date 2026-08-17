# frozen_string_literal: true

require 'test_helper'
require 'rails/generators/test_case'
require 'generators/metka/strategies/view/view_generator'

class ViewGeneratorTest < Rails::Generators::TestCase
  MIGRATION = 'db/migrate/create_tagged_notes_view.rb'

  tests Metka::Generators::Strategies::ViewGenerator
  destination File.expand_path('../../tmp', __dir__)

  setup do
    prepare_destination
    run_generator ['--source-table-name=notes']
  end

  test 'creates migration' do
    assert_migration MIGRATION
  end

  test 'up migration creates view' do
    assert_migration MIGRATION, /CREATE OR REPLACE VIEW tagged_notes/i
  end

  test 'down migration drops view' do
    assert_migration MIGRATION, /DROP VIEW/i
  end
end
