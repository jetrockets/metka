# frozen_string_literal: true

class CustomParser < Metka::GenericParser
  # A literal pipe. It no longer needs escaping for the Regexp — the parser
  # escapes the delimiter itself.
  private def delimiter
    "|"
  end
end
