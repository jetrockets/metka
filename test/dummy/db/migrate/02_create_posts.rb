# frozen_string_literal: true

class CreatePosts < ActiveRecord::Migration[5.0]
  def change
    sqlite = connection.adapter_name.match?(/sqlite/i)

    create_table :posts do |t|
      t.string :title
      t.integer :user_id, null: false
      if sqlite
        t.json :tags
        t.json :categories
      else
        t.string :tags, array: true
        t.string :categories, array: true
      end
      t.timestamps
    end
  end
end
