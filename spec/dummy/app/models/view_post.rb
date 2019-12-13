# frozen_string_literal: true

# This class use strategies view
# You can find out more here: lib/generators/metka/strategies/view/view_generator.rb
class ViewPost < ActiveRecord::Base
  include Metka::Model(column: 'tags')
  include Metka::Model(column: 'materials')

  belongs_to :user
end
