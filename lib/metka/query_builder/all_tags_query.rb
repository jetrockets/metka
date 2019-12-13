# frozen_string_literal: true

module Metka
  class AllTagsQuery < BaseQuery
    private

    def infix_operator
      '@>'
    end
  end
end
