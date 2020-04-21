class CustomParser < Metka::GenericParser
  DELIMITER = '\|'.freeze

  private

  def joined_delimiter
    DELIMITER
  end
end
