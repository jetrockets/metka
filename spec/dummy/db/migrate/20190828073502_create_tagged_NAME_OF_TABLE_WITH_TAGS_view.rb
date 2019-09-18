# frozen_string_literal: true

class CreateTaggedNameOfTableWithTagsView < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
    CREATE OR REPLACE MATERIALZIED VIEW tagged_NAME_OF_TABLE_WITH_TAGS AS

    SELECT UNNEST
      ( tags ) AS tag_name,
      COUNT ( * ) AS taggings_count
    FROM
      NAME_OF_TABLE_WITH_TAGS
    GROUP BY
      name;
    SQL
  end

  def down
    execute <<-SQL
      DROP VIEW tagged_NAME_OF_TABLE_WITH_TAGS;
    SQL
  end
end
