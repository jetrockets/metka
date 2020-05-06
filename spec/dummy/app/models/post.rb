# frozen_string_literal: true

# This class use ActiveRecord Strategy
class Post < ActiveRecord::Base
  include Metka::Model(columns: %w(tags categories))

  belongs_to :user
end
