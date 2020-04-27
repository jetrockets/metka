# frozen_string_literal: true

# This class use materialized view strategy
# You can find out more here: lib/generators/metka/strategies/materialized_view/materialized_view_generator.rb
class MaterializedViewPost < ActiveRecord::Base
  include Metka::Model(column: 'tags')

  belongs_to :user
end
