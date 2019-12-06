# frozen_string_literal: true

class CreateTaggedArticlesMaterializedView < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
    CREATE OR REPLACE FUNCTION metka_refresh_tagged_articles_materialized_view() RETURNS trigger LANGUAGE plpgsql AS $$
      BEGIN
        IF TG_OP = 'INSERT' AND NEW.tags IS NOT NULL THEN
          REFRESH MATERIALIZED VIEW CONCURRENTLY tagged_articles;
        END IF;

        IF TG_OP = 'UPDATE' AND OLD.tags != NEW.tags THEN
          REFRESH MATERIALIZED VIEW CONCURRENTLY tagged_articles;
        END IF;

        IF TG_OP = 'DELETE' AND OLD.tags IS NOT NULL THEN
          REFRESH MATERIALIZED VIEW CONCURRENTLY tagged_articles;
        END IF;
        RETURN NEW;
      END $$;

    DROP MATERIALIZED VIEW IF EXISTS tagged_articles;
    CREATE MATERIALIZED VIEW tagged_articles AS
      SELECT UNNEST
        ( tags ) AS tag_name,
        COUNT ( * ) AS taggings_count
      FROM
        articles
      GROUP BY
        tag_name;

    CREATE UNIQUE INDEX idx_articles_tags ON tagged_articles(tag_name);

    CREATE TRIGGER metka_on_articles
    AFTER UPDATE OR INSERT OR DELETE ON articles FOR EACH ROW
    EXECUTE PROCEDURE metka_refresh_tagged_articles_materialized_view();
    SQL
  end

  def down
    execute <<-SQL
      DROP TRIGGER IF EXISTS metka_on_articles ON articles;
      DROP MATERIALIZED VIEW IF EXISTS tagged_articles;
    SQL
  end
end
