# frozen_string_literal: true

require 'metka/version'

require 'active_support/core_ext/module'
require 'dry-configurable'

module Metka
  require 'metka/tag_list'
  require 'metka/generic_parser'
  require 'metka/query_builder'
  require 'metka/model'

  class Error < StandardError; end

  extend Dry::Configurable

  setting :parser, Metka::GenericParser
  setting :delimiter, default: ',', reader: true
end
