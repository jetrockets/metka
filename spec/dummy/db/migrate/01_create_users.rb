# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :tags, array: true

      t.timestamps
    end
  end
end
