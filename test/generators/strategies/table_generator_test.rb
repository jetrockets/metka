# frozen_string_literal: true

require "test_helper"
require "rails/generators/test_case"
require "generators/metka/strategies/table/table_generator"

class TableGeneratorTest < Rails::Generators::TestCase
  MIGRATION = "db/migrate/create_notes_tags_cloud_table.rb"
  SQLITE = ActiveRecord::Base.connection.adapter_name.match?(/sqlite/i)

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
    assert_migration MIGRATION, /CREATE TABLE notes_tags_cloud/i
  end

  test "up migration seeds the table from existing rows" do
    assert_migration MIGRATION, /INSERT INTO notes_tags_cloud \(tag_name, taggings_count\)\s+SELECT/i
  end

  test "up migration creates a trigger per operation" do
    assert_migration MIGRATION, /CREATE TRIGGER metka_ins_on_notes/i
    assert_migration MIGRATION, /CREATE TRIGGER metka_upd_on_notes/i
    assert_migration MIGRATION, /CREATE TRIGGER metka_del_on_notes/i
  end

  test "down migration drops every trigger" do
    assert_migration MIGRATION, /DROP TRIGGER IF EXISTS metka_ins_on_notes/i
    assert_migration MIGRATION, /DROP TRIGGER IF EXISTS metka_upd_on_notes/i
    assert_migration MIGRATION, /DROP TRIGGER IF EXISTS metka_del_on_notes/i
  end

  test "down migration drops table" do
    assert_migration MIGRATION, /DROP TABLE IF EXISTS notes_tags_cloud/i
  end

  if SQLITE
    test "up migration reads tags through json_each" do
      assert_migration MIGRATION, /json_each\(notes\.tags\)/i
      assert_migration MIGRATION, /json_each\(NEW\.tags\)/
      assert_migration MIGRATION, /json_each\(OLD\.tags\)/
    end

    test "up migration creates per-row triggers, and no PostgreSQL constructs" do
      assert_migration MIGRATION do |migration|
        assert_equal 3, migration.scan(/FOR EACH ROW/i).size
        assert_no_match(/FOR EACH STATEMENT/i, migration)
        assert_no_match(/LOCK TABLE/i, migration)
        assert_no_match(/CREATE OR REPLACE FUNCTION/i, migration)
        assert_no_match(/UNNEST\s*\(/i, migration)
      end
    end

    test "up migration upserts inside the trigger bodies" do
      assert_migration MIGRATION do |migration|
        assert_operator migration.scan(/ON CONFLICT \(tag_name\)/i).size, :>=, 2
      end
    end
  else
    test "up migration locks the source table before seeding" do
      assert_migration MIGRATION do |migration|
        lock = migration.index(/LOCK TABLE notes IN SHARE ROW EXCLUSIVE MODE/i)
        seed = migration.index(/INSERT INTO notes_tags_cloud/i)
        assert lock, "expected the migration to lock the source table"
        assert_operator lock, :<, seed, "expected the lock to be taken before the seed"
      end
    end

    test "up migration creates a function per operation" do
      assert_migration MIGRATION, /CREATE OR REPLACE FUNCTION metka_ins_notes_tags_cloud/i
      assert_migration MIGRATION, /CREATE OR REPLACE FUNCTION metka_upd_notes_tags_cloud/i
      assert_migration MIGRATION, /CREATE OR REPLACE FUNCTION metka_del_notes_tags_cloud/i
    end

    test "up migration creates statement-level triggers" do
      assert_migration MIGRATION do |migration|
        assert_equal 3, migration.scan(/FOR EACH STATEMENT/i).size
        assert_no_match(/FOR EACH ROW/i, migration)
      end
    end

    test "down migration drops every function" do
      assert_migration MIGRATION, /DROP FUNCTION IF EXISTS metka_ins_notes_tags_cloud/i
      assert_migration MIGRATION, /DROP FUNCTION IF EXISTS metka_upd_notes_tags_cloud/i
      assert_migration MIGRATION, /DROP FUNCTION IF EXISTS metka_del_notes_tags_cloud/i
    end
  end

  test "derives the name from the source columns when given" do
    prepare_destination
    run_generator [ "--source-table-name=notes", "--source-columns=tags", "genres" ]

    assert_migration "db/migrate/create_notes_tags_and_genres_cloud_table.rb",
      /CREATE TABLE notes_tags_and_genres_cloud/i
  end

  test "respects an explicit --table-name" do
    prepare_destination
    run_generator [ "--source-table-name=notes", "--table-name=note_cloud" ]

    assert_migration "db/migrate/create_note_cloud_table.rb", /CREATE TABLE note_cloud/i
  end

  # The options land verbatim in the migration's SQL, so anything that is not
  # a plain identifier must fail closed instead of producing surprising DDL.
  # Thor reports the Thor::Error on stderr and generates nothing.
  test "rejects a source table name that is not a plain identifier" do
    prepare_destination

    stderr = capture(:stderr) {
      run_generator [ "--source-table-name=notes; DROP TABLE users" ]
    }

    assert_match(/--source-table-name/, stderr)
    assert_empty Dir.glob("#{destination_root}/db/migrate/*")
  end

  test "rejects a source column that is not a plain identifier" do
    prepare_destination

    stderr = capture(:stderr) {
      run_generator [ "--source-table-name=notes", "--source-columns=tags)--" ]
    }

    assert_match(/--source-columns/, stderr)
    assert_empty Dir.glob("#{destination_root}/db/migrate/*")
  end

  test "rejects a table name that is not a plain identifier" do
    prepare_destination

    stderr = capture(:stderr) {
      run_generator [ "--source-table-name=notes", "--table-name=1cloud" ]
    }

    assert_match(/--table-name/, stderr)
    assert_empty Dir.glob("#{destination_root}/db/migrate/*")
  end
end
