# frozen_string_literal: true

module Metka
  class AnyTagsQuery < BaseQuery
    private

    def infix_operator
      "&&"
    end
  end
end
