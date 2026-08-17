# frozen_string_literal: true

# This class use view strategy
# You can find out more here: lib/generators/metka/strategies/view/view_generator.rb
class ViewPost < ActiveRecord::Base
  include Metka::Model(column: 'tags')

  belongs_to :user
end
