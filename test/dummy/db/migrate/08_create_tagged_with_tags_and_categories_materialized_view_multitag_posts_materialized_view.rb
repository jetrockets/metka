# frozen_string_literal: true

class CreateTaggedWithTagsAndCategoriesMaterializedViewMultitagPostsMaterializedView < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
    -- Statement-level triggers: one refresh per SQL statement, not per row.
    -- Guards must stay inside their TG_OP branch — a transition table is only
    -- registered for the firing trigger, so referencing the other one would
    -- fail to parse.
    CREATE OR REPLACE FUNCTION metka_refresh_tagged_with_tags_and_categories_materialized_view_multitag_posts_materialized_view() RETURNS trigger LANGUAGE plpgsql AS $$
      BEGIN
        IF TG_OP = 'INSERT' THEN
          IF NOT EXISTS (
            SELECT FROM new_rows
            WHERE tags IS NOT NULL OR categories IS NOT NULL
          ) THEN
            RETURN NULL;
          END IF;
        ELSIF TG_OP = 'UPDATE' THEN
          IF NOT EXISTS (
            (SELECT tags, categories FROM new_rows)
            EXCEPT ALL
            (SELECT tags, categories FROM old_rows)
          ) THEN
            RETURN NULL;
          END IF;
        ELSIF TG_OP = 'DELETE' THEN
          IF NOT EXISTS (
            SELECT FROM old_rows
            WHERE tags IS NOT NULL OR categories IS NOT NULL
          ) THEN
            RETURN NULL;
          END IF;
        END IF;

        REFRESH MATERIALIZED VIEW CONCURRENTLY tagged_with_tags_and_categories_materialized_view_multitag_posts;
        RETURN NULL;
      END $$;

    DROP MATERIALIZED VIEW IF EXISTS tagged_with_tags_and_categories_materialized_view_multitag_posts;
    CREATE MATERIALIZED VIEW tagged_with_tags_and_categories_materialized_view_multitag_posts AS
      SELECT
        tag_name,
        COUNT ( * ) AS taggings_count
      FROM (
        SELECT UNNEST
          ( tags || categories ) AS tag_name
        FROM
          materialized_view_multitag_posts
      ) subquery
      GROUP BY
        tag_name;

    CREATE UNIQUE INDEX idx_materialized_view_multitag_posts_tag_name ON tagged_with_tags_and_categories_materialized_view_multitag_posts(tag_name);

    -- The ins/upd/del discriminator sits at the front of the trigger names so
    -- they stay distinct even when PostgreSQL truncates identifiers to 63
    -- characters. One trigger per operation: a trigger with transition tables
    -- must be declared for exactly one event.
    CREATE TRIGGER metka_ins_on_materialized_view_multitag_posts_with_tags_and_categories
    AFTER INSERT ON materialized_view_multitag_posts
    REFERENCING NEW TABLE AS new_rows
    FOR EACH STATEMENT
    EXECUTE PROCEDURE metka_refresh_tagged_with_tags_and_categories_materialized_view_multitag_posts_materialized_view();

    CREATE TRIGGER metka_upd_on_materialized_view_multitag_posts_with_tags_and_categories
    AFTER UPDATE ON materialized_view_multitag_posts
    REFERENCING OLD TABLE AS old_rows NEW TABLE AS new_rows
    FOR EACH STATEMENT
    EXECUTE PROCEDURE metka_refresh_tagged_with_tags_and_categories_materialized_view_multitag_posts_materialized_view();

    CREATE TRIGGER metka_del_on_materialized_view_multitag_posts_with_tags_and_categories
    AFTER DELETE ON materialized_view_multitag_posts
    REFERENCING OLD TABLE AS old_rows
    FOR EACH STATEMENT
    EXECUTE PROCEDURE metka_refresh_tagged_with_tags_and_categories_materialized_view_multitag_posts_materialized_view();
    SQL
  end

  def down
    execute <<-SQL
      DROP TRIGGER IF EXISTS metka_ins_on_materialized_view_multitag_posts_with_tags_and_categories ON materialized_view_multitag_posts;
      DROP TRIGGER IF EXISTS metka_upd_on_materialized_view_multitag_posts_with_tags_and_categories ON materialized_view_multitag_posts;
      DROP TRIGGER IF EXISTS metka_del_on_materialized_view_multitag_posts_with_tags_and_categories ON materialized_view_multitag_posts;
      DROP MATERIALIZED VIEW IF EXISTS tagged_with_tags_and_categories_materialized_view_multitag_posts;
    SQL
  end
end
