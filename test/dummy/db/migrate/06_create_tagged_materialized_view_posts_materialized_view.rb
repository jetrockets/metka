# frozen_string_literal: true

class CreateTaggedMaterializedViewPostsMaterializedView < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
    -- Statement-level triggers: one refresh per SQL statement, not per row.
    -- Guards must stay inside their TG_OP branch — a transition table is only
    -- registered for the firing trigger, so referencing the other one would
    -- fail to parse.
    CREATE OR REPLACE FUNCTION metka_refresh_tagged_materialized_view_posts_materialized_view() RETURNS trigger LANGUAGE plpgsql AS $$
      BEGIN
        IF TG_OP = 'INSERT' THEN
          IF NOT EXISTS (
            SELECT FROM new_rows
            WHERE tags IS NOT NULL
          ) THEN
            RETURN NULL;
          END IF;
        ELSIF TG_OP = 'UPDATE' THEN
          IF NOT EXISTS (
            (SELECT tags FROM new_rows)
            EXCEPT ALL
            (SELECT tags FROM old_rows)
          ) THEN
            RETURN NULL;
          END IF;
        ELSIF TG_OP = 'DELETE' THEN
          IF NOT EXISTS (
            SELECT FROM old_rows
            WHERE tags IS NOT NULL
          ) THEN
            RETURN NULL;
          END IF;
        END IF;

        REFRESH MATERIALIZED VIEW CONCURRENTLY tagged_materialized_view_posts;
        RETURN NULL;
      END $$;

    DROP MATERIALIZED VIEW IF EXISTS tagged_materialized_view_posts;
    CREATE MATERIALIZED VIEW tagged_materialized_view_posts AS
      SELECT
        tag_name,
        COUNT ( * ) AS taggings_count
      FROM (
        SELECT UNNEST
          ( tags ) AS tag_name
        FROM
          materialized_view_posts
      ) subquery
      GROUP BY
        tag_name;

    CREATE UNIQUE INDEX idx_materialized_view_posts_tag_name ON tagged_materialized_view_posts(tag_name);

    CREATE TRIGGER metka_ins_on_materialized_view_posts
    AFTER INSERT ON materialized_view_posts
    REFERENCING NEW TABLE AS new_rows
    FOR EACH STATEMENT
    EXECUTE PROCEDURE metka_refresh_tagged_materialized_view_posts_materialized_view();

    CREATE TRIGGER metka_upd_on_materialized_view_posts
    AFTER UPDATE ON materialized_view_posts
    REFERENCING OLD TABLE AS old_rows NEW TABLE AS new_rows
    FOR EACH STATEMENT
    EXECUTE PROCEDURE metka_refresh_tagged_materialized_view_posts_materialized_view();

    CREATE TRIGGER metka_del_on_materialized_view_posts
    AFTER DELETE ON materialized_view_posts
    REFERENCING OLD TABLE AS old_rows
    FOR EACH STATEMENT
    EXECUTE PROCEDURE metka_refresh_tagged_materialized_view_posts_materialized_view();
    SQL
  end

  def down
    execute <<-SQL
      DROP TRIGGER IF EXISTS metka_ins_on_materialized_view_posts ON materialized_view_posts;
      DROP TRIGGER IF EXISTS metka_upd_on_materialized_view_posts ON materialized_view_posts;
      DROP TRIGGER IF EXISTS metka_del_on_materialized_view_posts ON materialized_view_posts;
      DROP MATERIALIZED VIEW IF EXISTS tagged_materialized_view_posts;
    SQL
  end
end
