# frozen_string_literal: true

# This class use strategies materialized view
# You can find out more here: lib/generators/metka/strategies/materialized_view/materialized_view_generator.rb
class MaterializedViewPost < ActiveRecord::Base
  include Metka::Model

  belongs_to :user
end
