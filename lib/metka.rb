# frozen_string_literal: true

require "metka/version"

require "active_support/core_ext/module"
require "dry-configurable"

module Metka
  # How multiple tag columns combine in a tagged_with query. These are the
  # public vocabulary, so they are plain symbols — Arel is an implementation
  # detail of the query builder and does not belong in a caller's code.
  AND = :and
  OR = :or

  require "metka/tag_list"
  require "metka/generic_parser"
  require "metka/query_builder"
  require "metka/model"

  class Error < StandardError; end

  extend Dry::Configurable

  setting :parser, default: Metka::GenericParser
  setting :delimiter, default: ",", reader: true
end
