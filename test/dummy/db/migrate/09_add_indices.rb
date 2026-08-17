# frozen_string_literal: true

class AddIndices < ActiveRecord::Migration[5.0]
  def change
    add_index :users, :tags, using: 'gin'
    add_index :posts, :tags, using: 'gin'
    add_index :posts, :categories, using: 'gin'
    add_index :view_posts, :tags, using: 'gin'
    add_index :materialized_view_posts, :tags, using: 'gin'
  end
end
