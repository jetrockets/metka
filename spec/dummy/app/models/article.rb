# frozen_string_literal: true

class Article < ActiveRecord::Base
  include Metka::Model

  belongs_to :user
end
