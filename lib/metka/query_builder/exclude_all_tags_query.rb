# frozen_string_literal: true

module Metka
  class ExcludeAllTagsQuery< BaseQuery
    private

    def infix_operator
      '@>'
    end
  end
end
