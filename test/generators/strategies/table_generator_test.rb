# frozen_string_literal: true

require "test_helper"
require "rails/generators/test_case"
require "generators/metka/strategies/table/table_generator"

class TableGeneratorTest < Rails::Generators::TestCase
  MIGRATION = "db/migrate/create_tagged_notes_table.rb"

  tests Metka::Generators::Strategies::TableGenerator
  destination File.expand_path("../../tmp", __dir__)

  setup do
    prepare_destination
    run_generator [ "--source-table-name=notes" ]
  end

  test "creates migration" do
    assert_migration MIGRATION
  end

  test "up migration creates table" do
    assert_migration MIGRATION, /CREATE TABLE tagged_notes/i
  end

  test "up migration seeds the table from existing rows" do
    assert_migration MIGRATION, /INSERT INTO tagged_notes \(tag_name, taggings_count\)\s+SELECT/i
  end

  test "up migration creates a function per operation" do
    assert_migration MIGRATION, /CREATE OR REPLACE FUNCTION metka_ins_tagged_notes/i
    assert_migration MIGRATION, /CREATE OR REPLACE FUNCTION metka_upd_tagged_notes/i
    assert_migration MIGRATION, /CREATE OR REPLACE FUNCTION metka_del_tagged_notes/i
  end

  test "up migration creates a statement-level trigger per operation" do
    assert_migration MIGRATION, /CREATE TRIGGER metka_ins_on_notes/i
    assert_migration MIGRATION, /CREATE TRIGGER metka_upd_on_notes/i
    assert_migration MIGRATION, /CREATE TRIGGER metka_del_on_notes/i
    assert_migration MIGRATION do |migration|
      assert_equal 3, migration.scan(/FOR EACH STATEMENT/i).size
      assert_no_match(/FOR EACH ROW/i, migration)
    end
  end

  test "down migration drops every trigger" do
    assert_migration MIGRATION, /DROP TRIGGER IF EXISTS metka_ins_on_notes/i
    assert_migration MIGRATION, /DROP TRIGGER IF EXISTS metka_upd_on_notes/i
    assert_migration MIGRATION, /DROP TRIGGER IF EXISTS metka_del_on_notes/i
  end

  test "down migration drops every function" do
    assert_migration MIGRATION, /DROP FUNCTION IF EXISTS metka_ins_tagged_notes/i
    assert_migration MIGRATION, /DROP FUNCTION IF EXISTS metka_upd_tagged_notes/i
    assert_migration MIGRATION, /DROP FUNCTION IF EXISTS metka_del_tagged_notes/i
  end

  test "down migration drops table" do
    assert_migration MIGRATION, /DROP TABLE IF EXISTS tagged_notes/i
  end
end
