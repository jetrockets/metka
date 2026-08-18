# frozen_string_literal: true

class CreateTablePosts < ActiveRecord::Migration[5.0]
  def change
    sqlite = connection.adapter_name.match?(/sqlite/i)

    create_table :table_posts do |t|
      t.string :title
      t.integer :user_id, null: false
      sqlite ? t.json(:tags) : t.string(:tags, array: true)

      t.timestamps
    end

    add_index :table_posts, :tags, using: "gin" unless sqlite
  end
end
