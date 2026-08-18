# frozen_string_literal: true

# Benchmarks Metka against other ActiveRecord tagging gems:
#
#   metka                     — PostgreSQL array column (this repo), JSON column on SQLite
#   acts-as-taggable-array-on — PostgreSQL array column
#   tag_columns               — PostgreSQL array column
#   acts-as-taggable-on       — normalized tags/taggings join tables
#   gutentag                  — normalized tags/taggings join tables
#
# Metka appears twice in the cloud/write suites, once per tag-cloud
# strategy: bare (no aggregate maintained) and table (statement triggers
# upsert per-tag deltas into a summary table). The strategy DDL matches the
# output of the metka:strategies:table generator.
#
# Usage:
#   bundle exec ruby benchmark.rb
#   DB=sqlite bundle exec ruby benchmark.rb
#
# The default run expects PostgreSQL reachable via the DB constant below (see
# docker command in README notes). DB=sqlite benchmarks against a local SQLite
# file instead; the PostgreSQL-array gems (acts-as-taggable-array-on,
# tag_columns) cannot run there and are skipped, and the metka trigger DDL is
# the per-row output of the generator's SQLite template. The whole database is
# dropped and re-seeded on every run.

$stdout.sync = true

require "bundler/setup"
require "active_record"
require "benchmark/ips"
require "benchmark"

SQLITE = %w[sqlite sqlite3].include?(ENV["DB"])

DB =
  if SQLITE
    {
      adapter: "sqlite3",
      database: File.expand_path("benchmark.sqlite3", __dir__),
      pool: 5
    }
  else
    {
      adapter: "postgresql",
      host: ENV.fetch("PGHOST", "127.0.0.1"),
      port: ENV.fetch("PGPORT", 5434),
      username: ENV.fetch("PGUSER", "bench"),
      password: ENV.fetch("PGPASSWORD", "bench"),
      database: ENV.fetch("PGDATABASE", "metka_bench"),
      pool: 5
    }
  end.freeze

File.delete(DB[:database]) if SQLITE && File.exist?(DB[:database])

POSTS_PER_GEM = Integer(ENV.fetch("POSTS", 10_000))
TAGS_PER_POST = 5
VOCABULARY = (1..100).map { |i| "tag#{format('%03d', i)}" }.freeze

ActiveRecord::Base.establish_connection(**DB)
ActiveRecord::Base.logger = nil
ActiveRecord::Migration.verbose = false

require "metka"
require "acts-as-taggable-on"
require "gutentag"

# PostgreSQL-array gems; their scopes cannot run on SQLite.
unless SQLITE
  require "acts-as-taggable-array-on"
  require "tag_columns"
end

# Gutentag's models normally load through its Rails engine; require them
# directly since this script boots plain ActiveRecord.
gutentag_root = Gem.loaded_specs["gutentag"].full_gem_path
require File.join(gutentag_root, "app/models/gutentag/tag")
require File.join(gutentag_root, "app/models/gutentag/tagging")

# ------------------------------------------------------------------ schema ---

def run_bundled_migrations(gem_name)
  dir = Pathname.new(Gem.loaded_specs[gem_name].full_gem_path).join("db/migrate")
  Dir[dir.join("*.rb")].sort.each { |file| require file }
end

ActiveRecord::Schema.define do
  drop_table :metka_posts, if_exists: true
  drop_table :metka_table_posts, if_exists: true, force: :cascade
  unless SQLITE
    drop_table :array_posts, if_exists: true
    drop_table :tag_columns_posts, if_exists: true
  end
  drop_table :ato_posts, if_exists: true
  drop_table :gutentag_posts, if_exists: true
  drop_table :taggings, if_exists: true
  drop_table :tags, if_exists: true
  drop_table :gutentag_taggings, if_exists: true
  drop_table :gutentag_tags, if_exists: true

  # On SQLite tags live in a JSON column; there is no index that can serve
  # membership-in-array predicates, so none is created.
  if SQLITE
    create_table :metka_posts do |t|
      t.string :title
      t.json :tags
    end

    create_table :metka_table_posts do |t|
      t.string :title
      t.json :tags
    end
  else
    create_table :metka_posts do |t|
      t.string :title
      t.string :tags, array: true
    end
    add_index :metka_posts, :tags, using: :gin

    create_table :metka_table_posts do |t|
      t.string :title
      t.string :tags, array: true
    end
    add_index :metka_table_posts, :tags, using: :gin

    create_table :array_posts do |t|
      t.string :title
      t.string :tags, array: true, default: []
    end
    add_index :array_posts, :tags, using: :gin

    create_table :tag_columns_posts do |t|
      t.string :title
      t.string :tags, array: true, default: []
    end
    add_index :tag_columns_posts, :tags, using: :gin
  end

  create_table :ato_posts do |t|
    t.string :title
  end

  create_table :gutentag_posts do |t|
    t.string :title
  end
end

run_bundled_migrations("acts-as-taggable-on")
[ ActsAsTaggableOnMigration, AddMissingUniqueIndices, AddTaggingsCounterCacheToTags,
 AddMissingTaggableIndex, ChangeCollationForTagNames, AddMissingIndexesOnTaggings,
 AddTenantToTaggings ].each { |m| m.migrate(:up) }

run_bundled_migrations("gutentag")
[ GutentagTables, GutentagCacheCounter, NoNullCounters ].each { |m| m.migrate(:up) }

# Tag-cloud strategy for the extra Metka table, as generated by `rails g
# metka:strategies:table` (comments stripped, names bound to the bench table).
# The SQLite variant matches the generator's SQLite template: per-row triggers
# upserting per-tag deltas read from NEW/OLD via json_each, one execute per
# statement since the sqlite3 driver runs one statement per call.
if SQLITE
  conn = ActiveRecord::Base.connection
  conn.execute("DROP TABLE IF EXISTS tagged_metka_table_posts")

  conn.execute(<<~SQL)
    CREATE TABLE tagged_metka_table_posts (
      tag_name varchar PRIMARY KEY,
      taggings_count bigint NOT NULL
    );
  SQL

  conn.execute(<<~SQL)
    INSERT INTO tagged_metka_table_posts (tag_name, taggings_count)
      SELECT value, COUNT(*)
      FROM metka_table_posts, json_each(metka_table_posts.tags)
      GROUP BY value;
  SQL

  conn.execute(<<~SQL)
    CREATE TRIGGER metka_ins_on_metka_table_posts_tags
    AFTER INSERT ON metka_table_posts
    FOR EACH ROW
    BEGIN
      INSERT INTO tagged_metka_table_posts (tag_name, taggings_count)
      SELECT value, 1 FROM json_each(NEW.tags) WHERE true
      ON CONFLICT (tag_name)
      DO UPDATE SET taggings_count = taggings_count + 1;
    END;
  SQL

  conn.execute(<<~SQL)
    CREATE TRIGGER metka_upd_on_metka_table_posts_tags
    AFTER UPDATE OF tags ON metka_table_posts
    FOR EACH ROW
    BEGIN
      INSERT INTO tagged_metka_table_posts (tag_name, taggings_count)
      SELECT value, 1 FROM json_each(NEW.tags) WHERE true
      ON CONFLICT (tag_name)
      DO UPDATE SET taggings_count = taggings_count + 1;

      UPDATE tagged_metka_table_posts
      SET taggings_count = taggings_count -
        (SELECT COUNT(*) FROM json_each(OLD.tags) WHERE value = tag_name)
      WHERE tag_name IN (SELECT value FROM json_each(OLD.tags));

      DELETE FROM tagged_metka_table_posts WHERE taggings_count <= 0;
    END;
  SQL

  conn.execute(<<~SQL)
    CREATE TRIGGER metka_del_on_metka_table_posts_tags
    AFTER DELETE ON metka_table_posts
    FOR EACH ROW
    BEGIN
      UPDATE tagged_metka_table_posts
      SET taggings_count = taggings_count -
        (SELECT COUNT(*) FROM json_each(OLD.tags) WHERE value = tag_name)
      WHERE tag_name IN (SELECT value FROM json_each(OLD.tags));

      DELETE FROM tagged_metka_table_posts WHERE taggings_count <= 0;
    END;
  SQL
else
ActiveRecord::Base.connection.execute(<<~SQL)
  DROP TABLE IF EXISTS tagged_metka_table_posts;
  CREATE TABLE tagged_metka_table_posts (
    tag_name varchar PRIMARY KEY,
    taggings_count bigint NOT NULL
  );

  INSERT INTO tagged_metka_table_posts (tag_name, taggings_count)
    SELECT tag_name, COUNT(*) AS taggings_count
    FROM (SELECT UNNEST(tags) AS tag_name FROM metka_table_posts) subquery
    GROUP BY tag_name;

  CREATE OR REPLACE FUNCTION metka_ins_tagged_metka_table_posts() RETURNS trigger LANGUAGE plpgsql AS $$
    BEGIN
      INSERT INTO tagged_metka_table_posts (tag_name, taggings_count)
      SELECT tag_name, COUNT(*)
      FROM (SELECT UNNEST(tags) AS tag_name FROM new_rows) subquery
      GROUP BY tag_name
      ON CONFLICT (tag_name)
      DO UPDATE SET taggings_count = tagged_metka_table_posts.taggings_count + EXCLUDED.taggings_count;
      RETURN NULL;
    END $$;

  CREATE OR REPLACE FUNCTION metka_upd_tagged_metka_table_posts() RETURNS trigger LANGUAGE plpgsql AS $$
    BEGIN
      WITH deltas AS (
        SELECT tag_name, SUM(d) AS delta
        FROM (
          SELECT UNNEST(tags) AS tag_name, 1 AS d FROM new_rows
          UNION ALL
          SELECT UNNEST(tags) AS tag_name, -1 AS d FROM old_rows
        ) changes
        GROUP BY tag_name
        HAVING SUM(d) <> 0
      )
      INSERT INTO tagged_metka_table_posts (tag_name, taggings_count)
      SELECT tag_name, delta FROM deltas
      ON CONFLICT (tag_name)
      DO UPDATE SET taggings_count = tagged_metka_table_posts.taggings_count + EXCLUDED.taggings_count;

      DELETE FROM tagged_metka_table_posts WHERE taggings_count <= 0;
      RETURN NULL;
    END $$;

  CREATE OR REPLACE FUNCTION metka_del_tagged_metka_table_posts() RETURNS trigger LANGUAGE plpgsql AS $$
    BEGIN
      UPDATE tagged_metka_table_posts
      SET taggings_count = tagged_metka_table_posts.taggings_count - removed.taggings_count
      FROM (
        SELECT tag_name, COUNT(*) AS taggings_count
        FROM (SELECT UNNEST(tags) AS tag_name FROM old_rows) subquery
        GROUP BY tag_name
      ) removed
      WHERE tagged_metka_table_posts.tag_name = removed.tag_name;

      DELETE FROM tagged_metka_table_posts WHERE taggings_count <= 0;
      RETURN NULL;
    END $$;

  CREATE TRIGGER metka_ins_on_metka_table_posts_tags
  AFTER INSERT ON metka_table_posts
  REFERENCING NEW TABLE AS new_rows
  FOR EACH STATEMENT
  EXECUTE PROCEDURE metka_ins_tagged_metka_table_posts();

  CREATE TRIGGER metka_upd_on_metka_table_posts_tags
  AFTER UPDATE ON metka_table_posts
  REFERENCING OLD TABLE AS old_rows NEW TABLE AS new_rows
  FOR EACH STATEMENT
  EXECUTE PROCEDURE metka_upd_tagged_metka_table_posts();

  CREATE TRIGGER metka_del_on_metka_table_posts_tags
  AFTER DELETE ON metka_table_posts
  REFERENCING OLD TABLE AS old_rows
  FOR EACH STATEMENT
  EXECUTE PROCEDURE metka_del_tagged_metka_table_posts();
SQL
end

# ------------------------------------------------------------------ models ---

class MetkaPost < ActiveRecord::Base
  self.table_name = "metka_posts"
  include Metka::Model(column: "tags")
end

class MetkaTablePost < ActiveRecord::Base
  self.table_name = "metka_table_posts"
  include Metka::Model(column: "tags")
end

class TaggedMetkaTablePost < ActiveRecord::Base
  self.table_name = "tagged_metka_table_posts"
end

unless SQLITE
  class ArrayPost < ActiveRecord::Base
    self.table_name = "array_posts"
    taggable_array :tags
  end

  class TagColumnsPost < ActiveRecord::Base
    self.table_name = "tag_columns_posts"
    include TagColumns
    tag_columns :tags
  end
end

class AtoPost < ActiveRecord::Base
  self.table_name = "ato_posts"
  acts_as_taggable_on :tags
end

class GutentagPost < ActiveRecord::Base
  self.table_name = "gutentag_posts"
  Gutentag::ActiveRecord.call self
end

# ------------------------------------------------------------------- seeds ---

rng = Random.new(42)
TAG_SETS = Array.new(POSTS_PER_GEM) { VOCABULARY.sample(TAGS_PER_POST, random: rng) }

def seed_with_insert_all(klass)
  TAG_SETS.each_slice(1_000).with_index do |slice, i|
    base = i * 1_000
    rows = slice.each_with_index.map do |tags, j|
      { title: "Post #{base + j}", tags: tags }
    end
    klass.insert_all(rows)
  end
end

def seed_with_create(klass, tags_writer)
  TAG_SETS.each_slice(500).with_index do |slice, i|
    base = i * 500
    klass.transaction do
      slice.each_with_index do |tags, j|
        record = klass.new(title: "Post #{base + j}")
        record.public_send(tags_writer, tags)
        record.save!
      end
    end
  end
end

puts "Seeding #{POSTS_PER_GEM} posts per gem, #{TAGS_PER_POST} tags each, " \
     "vocabulary of #{VOCABULARY.size} tags\n\n"

seed_times = {}
seed_times["metka"] = Benchmark.realtime { seed_with_insert_all(MetkaPost) }
seed_times["metka (table)"] = Benchmark.realtime { seed_with_insert_all(MetkaTablePost) }
unless SQLITE
  seed_times["acts-as-taggable-array-on"] = Benchmark.realtime { seed_with_insert_all(ArrayPost) }
  seed_times["tag_columns"] = Benchmark.realtime { seed_with_insert_all(TagColumnsPost) }
end
seed_times["acts-as-taggable-on"] = Benchmark.realtime { seed_with_create(AtoPost, :tag_list=) }
seed_times["gutentag"] = Benchmark.realtime { seed_with_create(GutentagPost, :tag_names=) }

puts "Bulk seed wall time (#{POSTS_PER_GEM} posts):"
seed_times.each { |name, t| puts format("  %-28s %8.2f s", name, t) }
puts

# ------------------------------------------------------------ storage size ---

# Per-relation bytes including indexes. On SQLite this reads the dbstat
# virtual table (pages actually used by each btree), summing the table and
# every index sqlite_master attributes to it.
def relation_size(*tables)
  conn = ActiveRecord::Base.connection

  tables.sum do |t|
    if SQLITE
      names = conn.select_values(<<~SQL)
        SELECT name FROM sqlite_master
        WHERE tbl_name = #{conn.quote(t)} AND type IN ('table', 'index')
      SQL
      names.sum { |n| conn.select_value("SELECT SUM(pgsize) FROM dbstat WHERE name = #{conn.quote(n)}").to_i }
    else
      conn.select_value("SELECT pg_total_relation_size(#{conn.quote(t)})").to_i
    end
  end
end

sizes = {
  "metka" => relation_size("metka_posts"),
  "metka (table)" => relation_size("metka_table_posts", "tagged_metka_table_posts"),
  "acts-as-taggable-on" => relation_size("ato_posts", "tags", "taggings"),
  "gutentag" => relation_size("gutentag_posts", "gutentag_tags", "gutentag_taggings")
}
unless SQLITE
  sizes["acts-as-taggable-array-on"] = relation_size("array_posts")
  sizes["tag_columns"] = relation_size("tag_columns_posts")
end

puts "Storage (tables + indexes) for #{POSTS_PER_GEM} posts:"
sizes.each { |name, s| puts format("  %-28s %8.2f MB", name, s / 1024.0 / 1024.0) }
puts

ActiveRecord::Base.connection.execute(SQLITE ? "ANALYZE" : "VACUUM ANALYZE")

# ------------------------------------------------------------- query pairs ---

pair_rng = Random.new(7)
PAIRS = Array.new(100) { VOCABULARY.sample(2, random: pair_rng) }

def next_pair
  @pair_index = (@pair_index || 0) + 1
  PAIRS[@pair_index % PAIRS.size]
end

# -------------------------------------------------------------- benchmarks ---

# WRITE_ONLY=1 skips the read suites; used to rerun the write suites alone.
WRITE_ONLY = ENV["WRITE_ONLY"] == "1"

unless WRITE_ONLY
puts "=" * 72
puts "QUERY: tagged with ALL of 2 tags -> load records (~#{(POSTS_PER_GEM * (TAGS_PER_POST / 100.0)**2).round} rows)"
puts "=" * 72
Benchmark.ips do |x|
  x.config(warmup: 2, time: 5)
  x.report("metka") { MetkaPost.tagged_with(next_pair).to_a }
  unless SQLITE
    x.report("acts-as-taggable-array-on") { ArrayPost.with_all_tags(next_pair).to_a }
    x.report("tag_columns") { TagColumnsPost.with_all_tags(*next_pair).to_a }
  end
  x.report("acts-as-taggable-on") { AtoPost.tagged_with(next_pair).to_a }
  x.report("gutentag") { GutentagPost.tagged_with(names: next_pair, match: :all).to_a }
  x.compare!
end

puts "=" * 72
puts "QUERY: tagged with ANY of 2 tags -> count"
puts "=" * 72
Benchmark.ips do |x|
  x.config(warmup: 2, time: 5)
  x.report("metka") { MetkaPost.tagged_with(next_pair, any: true).count }
  unless SQLITE
    x.report("acts-as-taggable-array-on") { ArrayPost.with_any_tags(next_pair).count }
    x.report("tag_columns") { TagColumnsPost.with_any_tags(*next_pair).count }
  end
  # ATO's relation counts via COUNT("ato_posts".*); SQLite cannot parse
  # table.* inside an aggregate, so count(:all) (plain COUNT(*)) is used
  # there — same rows counted, the EXISTS filter dedups either way.
  x.report("acts-as-taggable-on") do
    relation = AtoPost.tagged_with(next_pair, any: true)
    SQLITE ? relation.count(:all) : relation.count
  end
  x.report("gutentag") { GutentagPost.tagged_with(names: next_pair, match: :any).count }
  x.compare!
end

puts "=" * 72
puts "TAG CLOUD: tag -> usage count across all #{POSTS_PER_GEM} posts"
puts "=" * 72
Benchmark.ips do |x|
  x.config(warmup: 2, time: 5)
  x.report("metka") { MetkaPost.tag_cloud }
  x.report("metka (table)") { TaggedMetkaTablePost.pluck(:tag_name, :taggings_count) }
  unless SQLITE
    x.report("acts-as-taggable-array-on") { ArrayPost.tags_cloud }
    x.report("tag_columns") { TagColumnsPost.tags_cloud }
  end
  x.report("acts-as-taggable-on") { AtoPost.tag_counts_on(:tags).map { |t| [ t.name, t.count ] } }
  x.report("gutentag") do
    Gutentag::Tag.joins(:taggings)
      .where(gutentag_taggings: { taggable_type: "GutentagPost" })
      .group(:name).count
  end
  x.compare!
end
end

puts "=" * 72
puts "WRITE: create one post with #{TAGS_PER_POST} tags"
puts "=" * 72
create_rng = Random.new(1)
CREATE_SETS = Array.new(1_000) { VOCABULARY.sample(TAGS_PER_POST, random: create_rng) }

def next_create_set
  @create_index = (@create_index || 0) + 1
  CREATE_SETS[@create_index % CREATE_SETS.size]
end

Benchmark.ips do |x|
  x.config(warmup: 2, time: 5)
  x.report("metka") do
    p = MetkaPost.new(title: "bench")
    p.tag_list = next_create_set
    p.save!
  end
  x.report("metka (table)") do
    p = MetkaTablePost.new(title: "bench")
    p.tag_list = next_create_set
    p.save!
  end
  unless SQLITE
    x.report("acts-as-taggable-array-on") { ArrayPost.create!(title: "bench", tags: next_create_set) }
    x.report("tag_columns") { TagColumnsPost.create!(title: "bench", tags: next_create_set) }
  end
  x.report("acts-as-taggable-on") do
    p = AtoPost.new(title: "bench")
    p.tag_list = next_create_set
    p.save!
  end
  x.report("gutentag") do
    p = GutentagPost.new(title: "bench")
    p.tag_names = next_create_set
    p.save!
  end
  x.compare!
end

puts "=" * 72
puts "WRITE: replace the tag list of an existing post"
puts "=" * 72
update_ids = {
  metka: MetkaPost.limit(1_000).pluck(:id),
  metka_table: MetkaTablePost.limit(1_000).pluck(:id),
  ato: AtoPost.limit(1_000).pluck(:id),
  gutentag: GutentagPost.limit(1_000).pluck(:id)
}
unless SQLITE
  update_ids[:array] = ArrayPost.limit(1_000).pluck(:id)
  update_ids[:tc] = TagColumnsPost.limit(1_000).pluck(:id)
end

def next_id(ids)
  @id_index = (@id_index || 0) + 1
  ids[@id_index % ids.size]
end

Benchmark.ips do |x|
  x.config(warmup: 2, time: 5)
  x.report("metka") do
    p = MetkaPost.find(next_id(update_ids[:metka]))
    p.tag_list = next_create_set
    p.save!
  end
  x.report("metka (table)") do
    p = MetkaTablePost.find(next_id(update_ids[:metka_table]))
    p.tag_list = next_create_set
    p.save!
  end
  unless SQLITE
    x.report("acts-as-taggable-array-on") do
      ArrayPost.find(next_id(update_ids[:array])).update!(tags: next_create_set)
    end
    x.report("tag_columns") do
      TagColumnsPost.find(next_id(update_ids[:tc])).update!(tags: next_create_set)
    end
  end
  x.report("acts-as-taggable-on") do
    p = AtoPost.find(next_id(update_ids[:ato]))
    p.tag_list = next_create_set
    p.save!
  end
  x.report("gutentag") do
    p = GutentagPost.find(next_id(update_ids[:gutentag]))
    p.tag_names = next_create_set
    p.save!
  end
  x.compare!
end

# --------------------------------------------------------- integrity check ---

def cloud_mismatches(source_table, summary_table)
  live_tags =
    if SQLITE
      "SELECT value AS tag_name FROM #{source_table}, json_each(#{source_table}.tags)"
    else
      "SELECT UNNEST(tags) AS tag_name FROM #{source_table}"
    end
  # SQLite has no IS DISTINCT FROM; its IS / IS NOT are the null-safe forms.
  distinct_from = SQLITE ? "IS NOT" : "IS DISTINCT FROM"

  ActiveRecord::Base.connection.select_value(<<~SQL).to_i
    SELECT COUNT(*)
    FROM (
      SELECT tag_name, COUNT(*) AS cnt
      FROM (#{live_tags}) s
      GROUP BY tag_name
    ) live
    FULL OUTER JOIN #{summary_table} summary USING (tag_name)
    WHERE summary.taggings_count #{distinct_from} live.cnt
  SQL
end

puts
puts "Strategy integrity after all suites (0 = aggregate matches a live aggregation):"
puts "  table mismatching tags: #{cloud_mismatches('metka_table_posts', 'tagged_metka_table_posts')}"
