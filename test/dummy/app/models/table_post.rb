# frozen_string_literal: true

# This class use table strategy
# You can find out more here: lib/generators/metka/strategies/table/table_generator.rb
class TablePost < ActiveRecord::Base
  include Metka::Model(column: "tags")

  belongs_to :user
end
