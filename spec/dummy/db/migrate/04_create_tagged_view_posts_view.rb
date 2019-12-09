# frozen_string_literal: true

class CreateTaggedViewPostsView < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
    CREATE OR REPLACE VIEW tagged_view_posts AS

    SELECT UNNEST
      ( tags ) AS tag_name,
      COUNT ( * ) AS taggings_count
    FROM
      view_posts
    GROUP BY
      tag_name;
    SQL
  end

  def down
    execute <<-SQL
      DROP VIEW tagged_view_posts;
    SQL
  end
end
