# frozen_string_literal: true

class CreateTaggedTablePostsTable < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
    -- A real table maintained by per-tag deltas: statement-level triggers read
    -- the transition tables and upsert only the tags the statement touched, so
    -- maintenance cost is O(tags touched) instead of a full recompute. Writes
    -- that bypass these triggers (TRUNCATE, restoring from a dump) require
    -- reseeding the table by hand.

    -- Block writes (reads stay unblocked) until the triggers exist: a write
    -- committing between the seed's snapshot and CREATE TRIGGER would be seen
    -- by neither and drift the counts. CREATE TRIGGER takes this same lock
    -- level anyway; this only takes it before the seed instead of after.
    LOCK TABLE table_posts IN SHARE ROW EXCLUSIVE MODE;

    CREATE TABLE tagged_table_posts (
      tag_name varchar PRIMARY KEY,
      taggings_count bigint NOT NULL
    );

    INSERT INTO tagged_table_posts (tag_name, taggings_count)
      SELECT
        tag_name,
        COUNT(*) AS taggings_count
      FROM (
        SELECT UNNEST
          (tags) AS tag_name
        FROM
          table_posts
      ) subquery
      GROUP BY
        tag_name;

    -- UNNEST of a NULL array yields no rows and array concatenation treats a
    -- NULL operand as empty, so NULL tagged columns need no explicit guards.
    -- One function per operation: a transition table is only registered for
    -- its own trigger, so the other operations' functions would fail to parse.
    CREATE OR REPLACE FUNCTION metka_ins_tagged_table_posts() RETURNS trigger LANGUAGE plpgsql AS $$
      BEGIN
        INSERT INTO tagged_table_posts (tag_name, taggings_count)
        SELECT tag_name, COUNT(*)
        FROM (
          SELECT UNNEST (tags) AS tag_name
          FROM new_rows
        ) subquery
        GROUP BY tag_name
        ON CONFLICT (tag_name)
        DO UPDATE SET taggings_count = tagged_table_posts.taggings_count + EXCLUDED.taggings_count;
        RETURN NULL;
      END $$;

    CREATE OR REPLACE FUNCTION metka_upd_tagged_table_posts() RETURNS trigger LANGUAGE plpgsql AS $$
      BEGIN
        WITH deltas AS (
          SELECT tag_name, SUM(d) AS delta
          FROM (
            SELECT UNNEST (tags) AS tag_name, 1 AS d FROM new_rows
            UNION ALL
            SELECT UNNEST (tags) AS tag_name, -1 AS d FROM old_rows
          ) changes
          GROUP BY tag_name
          HAVING SUM(d) <> 0
        )
        INSERT INTO tagged_table_posts (tag_name, taggings_count)
        SELECT tag_name, delta FROM deltas
        ON CONFLICT (tag_name)
        DO UPDATE SET taggings_count = tagged_table_posts.taggings_count + EXCLUDED.taggings_count;

        DELETE FROM tagged_table_posts WHERE taggings_count <= 0;
        RETURN NULL;
      END $$;

    CREATE OR REPLACE FUNCTION metka_del_tagged_table_posts() RETURNS trigger LANGUAGE plpgsql AS $$
      BEGIN
        UPDATE tagged_table_posts
        SET taggings_count = tagged_table_posts.taggings_count - removed.taggings_count
        FROM (
          SELECT tag_name, COUNT(*) AS taggings_count
          FROM (
            SELECT UNNEST (tags) AS tag_name
            FROM old_rows
          ) subquery
          GROUP BY tag_name
        ) removed
        WHERE tagged_table_posts.tag_name = removed.tag_name;

        DELETE FROM tagged_table_posts WHERE taggings_count <= 0;
        RETURN NULL;
      END $$;

    -- The ins/upd/del discriminator sits at the front of the trigger names so
    -- they stay distinct even when PostgreSQL truncates identifiers to 63
    -- characters. One trigger per operation: a trigger with transition tables
    -- must be declared for exactly one event.
    CREATE TRIGGER metka_ins_on_table_posts_tags
    AFTER INSERT ON table_posts
    REFERENCING NEW TABLE AS new_rows
    FOR EACH STATEMENT
    EXECUTE PROCEDURE metka_ins_tagged_table_posts();

    CREATE TRIGGER metka_upd_on_table_posts_tags
    AFTER UPDATE ON table_posts
    REFERENCING OLD TABLE AS old_rows NEW TABLE AS new_rows
    FOR EACH STATEMENT
    EXECUTE PROCEDURE metka_upd_tagged_table_posts();

    CREATE TRIGGER metka_del_on_table_posts_tags
    AFTER DELETE ON table_posts
    REFERENCING OLD TABLE AS old_rows
    FOR EACH STATEMENT
    EXECUTE PROCEDURE metka_del_tagged_table_posts();
    SQL
  end

  def down
    execute <<-SQL
      DROP TRIGGER IF EXISTS metka_ins_on_table_posts_tags ON table_posts;
      DROP TRIGGER IF EXISTS metka_upd_on_table_posts_tags ON table_posts;
      DROP TRIGGER IF EXISTS metka_del_on_table_posts_tags ON table_posts;
      DROP FUNCTION IF EXISTS metka_ins_tagged_table_posts;
      DROP FUNCTION IF EXISTS metka_upd_tagged_table_posts;
      DROP FUNCTION IF EXISTS metka_del_tagged_table_posts;
      DROP TABLE IF EXISTS tagged_table_posts;
    SQL
  end
end
