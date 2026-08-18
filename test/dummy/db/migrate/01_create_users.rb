# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    sqlite = connection.adapter_name.match?(/sqlite/i)

    create_table :users do |t|
      t.string :name, null: false
      # SQLite has no array type; tags are stored as a JSON array in a text
      # column, which the sqlite3 adapter round-trips as a Ruby Array.
      sqlite ? t.json(:tags) : t.string(:tags, array: true)

      t.timestamps
    end
  end
end
