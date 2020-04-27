# frozen_string_literal: true

class CreateTaggedMaterializedViewPostsMaterializedView < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
    CREATE OR REPLACE FUNCTION metka_refresh_tagged_materialized_view_posts_materialized_view() RETURNS trigger LANGUAGE plpgsql AS $$
      BEGIN
        IF TG_OP = 'INSERT' AND NEW.tags IS NOT NULL THEN
          REFRESH MATERIALIZED VIEW CONCURRENTLY tagged_materialized_view_posts;
        END IF;

        IF TG_OP = 'UPDATE' AND OLD.tags IS DISTINCT FROM NEW.tags THEN
          REFRESH MATERIALIZED VIEW CONCURRENTLY tagged_materialized_view_posts;
        END IF;

        IF TG_OP = 'DELETE' AND OLD.tags IS NOT NULL THEN
          REFRESH MATERIALIZED VIEW CONCURRENTLY tagged_materialized_view_posts;
        END IF;
        RETURN NEW;
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

    CREATE TRIGGER metka_on_materialized_view_posts
    AFTER UPDATE OR INSERT OR DELETE ON materialized_view_posts FOR EACH ROW
    EXECUTE PROCEDURE metka_refresh_tagged_materialized_view_posts_materialized_view();
    SQL
  end

  def down
    execute <<-SQL
      DROP TRIGGER IF EXISTS metka_on_materialized_view_posts ON materialized_view_posts;
      DROP MATERIALIZED VIEW IF EXISTS tagged_materialized_view_posts;
    SQL
  end
end
