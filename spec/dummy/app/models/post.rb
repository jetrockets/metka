# frozen_string_literal: true

class Post < ActiveRecord::Base
  include Metka::Model
  
  belongs_to :user
end