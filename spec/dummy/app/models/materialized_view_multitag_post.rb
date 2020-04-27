# frozen_string_literal: true

# This class use materialized view strategy with aggregation by multiple tagged columns
# You can find out more here: lib/generators/metka/strategies/materialized_view/materialized_view_generator.rb
class MaterializedViewMultitagPost < ActiveRecord::Base
  include Metka::Model(column: 'tags')
  include Metka::Model(column: 'materials')

  belongs_to :user
end
