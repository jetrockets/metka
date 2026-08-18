# frozen_string_literal: true

class CreateTablePosts < ActiveRecord::Migration[5.0]
  def change
    create_table :table_posts do |t|
      t.string :title
      t.integer :user_id, null: false
      t.string :tags, array: true

      t.timestamps
    end

    add_index :table_posts, :tags, using: "gin"
  end
end
