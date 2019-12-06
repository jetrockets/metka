# frozen_string_literal: true

class CreateTaggedPostsView < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
    CREATE OR REPLACE VIEW tagged_posts AS

    SELECT UNNEST
      ( tags ) AS tag_name,
      COUNT ( * ) AS taggings_count
    FROM
      posts
    GROUP BY
      tag_name;
    SQL
  end

  def down
    execute <<-SQL
      DROP VIEW tagged_posts;
    SQL
  end
end
