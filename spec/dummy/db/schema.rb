# frozen_string_literal: true

ActiveRecord::Schema.define version: 0 do
  create_table :users, force: true do |t|
    t.string :name, null: false
    t.timestamp "created_at"
    t.timestamp "updated_at"
  end

  create_table :posts, force: true do |t|
    t.integer :user_id, null: false
    t.string :title, null: false
    t.string :tags, array: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end
end
