# frozen_string_literal: true

ActiveRecord::Schema.define version: 0 do
  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.timestamp "created_at", null: false
    t.timestamp "updated_at", null: false
  end

  create_table "posts", force: :cascade do |t|
    t.string "title"
    t.integer "user_id", null: false
    t.string "tags", array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
