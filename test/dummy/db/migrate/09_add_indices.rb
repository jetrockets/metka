# frozen_string_literal: true

class AddIndices < ActiveRecord::Migration[5.0]
  # GIN indexes are PostgreSQL-only. SQLite has no index type that accelerates
  # membership-in-JSON-array predicates, so it gets no indexes at all — tag
  # queries there are table scans by design.
  def change
    return if connection.adapter_name.match?(/sqlite/i)

    add_index :users, :tags, using: "gin"
    add_index :posts, :tags, using: "gin"
    add_index :posts, :categories, using: "gin"
  end
end
