# frozen_string_literal: true

class CreateTaggedUsersView < ActiveRecord::Migration[5.0]
  def up
    add_column :users, :tags, :string, array: true
  end

  def down
    remove_column :users, :tags, :string, array: true
  end
end
