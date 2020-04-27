# frozen_string_literal: true

class User < ActiveRecord::Base
  has_many :materialized_view_posts
  has_many :posts


  include Metka::Model(column: 'tags', parser: CustomParser.instance)
end
