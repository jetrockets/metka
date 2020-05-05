# frozen_string_literal: true

# This class use ActiveRecord Strategy
class Post < ActiveRecord::Base
  include Metka::Model(column: 'tags')
  include Metka::Model(column: 'categories', parser: CustomParser.instance)

  belongs_to :user
end
