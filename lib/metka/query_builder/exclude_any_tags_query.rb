# frozen_string_literal: true

module Metka
  class ExcludeAnyTagsQuery< BaseQuery
    private

    def infix_operator
      '@>'
    end
  end
end
