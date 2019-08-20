# frozen_string_literal: true

require 'metka/version'
require 'metka/tag_list'
require 'metka/generic_parser'

require 'active_support/core_ext/module'
require 'dry-configurable'

module Metka
  class Error < StandardError; end

  extend Dry::Configurable

  setting :parser, Metka::GenericParser
  setting :delimiter, ','
end
