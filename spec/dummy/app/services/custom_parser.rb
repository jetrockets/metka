# frozen_string_literal: true

class CustomParser < Metka::GenericParser
  DELIMITER = '\|'.freeze

  private

  def joined_delimiter
    DELIMITER
  end
end
