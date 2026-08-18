# frozen_string_literal: true

require "metka/version"

require "active_support/core_ext/module"

module Metka
  require "metka/tag_list"
  require "metka/generic_parser"
  require "metka/query_builder"
  require "metka/model"

  class Error < StandardError; end

  mattr_accessor :parser, default: Metka::GenericParser
  mattr_accessor :delimiter, default: ","

  # These two settings came from dry-configurable, which reached them through
  # Metka.config. Nothing else in the gem needed that gem, so it is gone and
  # the entry points it provided forward to the module itself.
  def self.config
    self
  end

  def self.configure
    yield self
  end
end
