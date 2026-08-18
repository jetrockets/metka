# frozen_string_literal: true

require "test_helper"

class MetkaTest < ActiveSupport::TestCase
  teardown do
    Metka.delimiter = ","
    Metka.parser = Metka::GenericParser
  end

  test "has a version number" do
    refute_nil Metka::VERSION
  end

  # These two settings came from dry-configurable and were reached through
  # Metka.config, which the README documents. Both paths still work.
  test "exposes the parser and delimiter directly" do
    assert_equal Metka::GenericParser, Metka.parser
    assert_equal ",", Metka.delimiter
  end

  test "still exposes them through Metka.config" do
    assert_equal Metka.parser, Metka.config.parser
    assert_equal Metka.delimiter, Metka.config.delimiter
  end

  test "writes through either path" do
    Metka.config.delimiter = "/"
    assert_equal "/", Metka.delimiter

    Metka.delimiter = ";"
    assert_equal ";", Metka.config.delimiter
  end

  test "still yields to Metka.configure" do
    Metka.configure { |config| config.delimiter = "/" }

    assert_equal "/", Metka.delimiter
  end

  test "a reconfigured delimiter reaches the parser" do
    Metka.config.delimiter = ";"

    assert_equal %w[a b], Metka::GenericParser.instance.call("a;b").to_a
  end
end
