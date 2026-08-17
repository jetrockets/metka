# frozen_string_literal: true

class CreateTaggedWithTagsAndCategoriesMaterializedViewMultitagPostsMaterializedView < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
    CREATE OR REPLACE FUNCTION metka_refresh_tagged_with_tags_and_categories_materialized_view_multitag_posts_materialized_view() RETURNS trigger LANGUAGE plpgsql AS $$
      BEGIN
        IF TG_OP = 'INSERT' AND (NEW.tags IS NOT NULL OR NEW.categories IS NOT NULL) THEN
          REFRESH MATERIALIZED VIEW CONCURRENTLY tagged_with_tags_and_categories_materialized_view_multitag_posts;
        END IF;

        IF TG_OP = 'UPDATE' AND (OLD.tags IS DISTINCT FROM NEW.tags OR OLD.categories IS DISTINCT FROM NEW.categories) THEN
          REFRESH MATERIALIZED VIEW CONCURRENTLY tagged_with_tags_and_categories_materialized_view_multitag_posts;
        END IF;

        IF TG_OP = 'DELETE' AND (OLD.tags IS NOT NULL OR OLD.categories IS NOT NULL) THEN
          REFRESH MATERIALIZED VIEW CONCURRENTLY tagged_with_tags_and_categories_materialized_view_multitag_posts;
        END IF;
        RETURN NEW;
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

    CREATE TRIGGER metka_on_materialized_view_multitag_posts_with_tags_and_categories
    AFTER UPDATE OR INSERT OR DELETE ON materialized_view_multitag_posts FOR EACH ROW
    EXECUTE PROCEDURE metka_refresh_tagged_with_tags_and_categories_materialized_view_multitag_posts_materialized_view();
    SQL
  end

  def down
    execute <<-SQL
      DROP TRIGGER IF EXISTS metka_on_materialized_view_multitag_posts_with_tags_and_categories ON materialized_view_multitag_posts;
      DROP MATERIALIZED VIEW IF EXISTS tagged_with_tags_and_categories_materialized_view_multitag_posts;
    SQL
  end
end
