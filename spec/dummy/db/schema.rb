# frozen_string_literal: true

ActiveRecord::Schema.define version: 0 do
  create_table :taggable_models, force: true do |t|
    t.string :name
    t.string :tags, array: true
  end
end