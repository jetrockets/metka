# frozen_string_literal: true

require "test_helper"
require "rails/generators/test_case"
require "generators/metka/strategies/index/index_generator"

class IndexGeneratorTest < Rails::Generators::TestCase
  MIGRATION = "db/migrate/create_notes_tags_and_labels_index_tables.rb"
  SQLITE = ActiveRecord::Base.connection.adapter_name.match?(/sqlite/i)

  tests Metka::Generators::Strategies::IndexGenerator
  destination File.expand_path("../../tmp", __dir__)

  setup do
    prepare_destination
    run_generator [ "--source-table-name=notes", "--source-columns", "tags", "labels" ]
  end

  if SQLITE
    test "creates one WITHOUT ROWID index table per column" do
      assert_migration MIGRATION, /CREATE TABLE notes_tags_index/i
      assert_migration MIGRATION, /CREATE TABLE notes_labels_index/i
      assert_migration MIGRATION do |migration|
        assert_equal 2, migration.scan(/WITHOUT ROWID/i).size
      end
    end

    test "seeds each index table from existing rows" do
      assert_migration MIGRATION, /INSERT OR IGNORE INTO notes_tags_index \(tag_name, record_id\)\s+SELECT value, notes\.id/i
      assert_migration MIGRATION, /json_each\(notes\.labels\)/i
    end

    test "creates per-row triggers per column and operation" do
      %w[tags labels].each do |column|
        assert_migration MIGRATION, /CREATE TRIGGER metka_idx_ins_on_notes_#{column}/i
        assert_migration MIGRATION, /CREATE TRIGGER metka_idx_upd_on_notes_#{column}/i
        assert_migration MIGRATION, /CREATE TRIGGER metka_idx_del_on_notes_#{column}/i
      end
      assert_migration MIGRATION do |migration|
        assert_equal 6, migration.scan(/FOR EACH ROW/).size
      end
    end

    test "documents the index_tables declaration for the model" do
      assert_migration MIGRATION, /"tags" => "notes_tags_index"/
      assert_migration MIGRATION, /"labels" => "notes_labels_index"/
    end

    test "down migration drops every trigger and table" do
      %w[tags labels].each do |column|
        assert_migration MIGRATION, /DROP TRIGGER IF EXISTS metka_idx_ins_on_notes_#{column}/i
        assert_migration MIGRATION, /DROP TABLE IF EXISTS notes_#{column}_index/i
      end
    end
  else
    test "generates nothing on PostgreSQL, where GIN indexes already serve queries" do
      assert_no_migration MIGRATION
    end
  end
end
