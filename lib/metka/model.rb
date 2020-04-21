# frozen_string_literal: true

require_relative 'model/integration'

module Metka
  module Model
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def has_metka(&block)
        Metka::Model::Integration.new(self).integrate!(&block)
      end
    end
  end
end
