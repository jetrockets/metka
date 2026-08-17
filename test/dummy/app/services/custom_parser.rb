# frozen_string_literal: true

class CustomParser < Metka::GenericParser
  private def delimiter
    '\|'
  end
end
