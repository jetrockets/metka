# frozen_string_literal: true

class CustomParser < Metka::GenericParser
  private def joined_delimiter
    '\|'
  end
end
