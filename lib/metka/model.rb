# frozen_string_literal: true

require 'arel'

module Metka
  OR = Arel::Nodes::Or
  AND = Arel::Nodes::And

  def self.Model(column: nil, columns: nil, **options)
    columns = [column, *columns].uniq.compact
    raise ArgumentError, 'Columns not specified' unless columns.present?

    Metka::Model.new(columns: columns, **options)
  end

  class Model < Module
    def initialize(columns:, **options)
      @columns = columns.dup.freeze
      @options = options.dup.freeze
    end

    def included(base)
      columns = @columns
      parser = ->(tags) {
        @options[:parser] ? @options[:parser].call(tags) : Metka.config.parser.instance.call(tags)
      }

      # @param model [ActiveRecord::Base] model on which to execute search
      # @param tags [Object] list of tags, representation depends on parser used
      # @param options [Hash] options
      #   @option :join_operator [Metka::AND, Metka::OR]
      #   @option :on [Array<String>] list of column names to include in query
      # @returns ViewPost::ActiveRecord_Relation
      tagged_with_lambda = ->(model, tags, **options) {
        cols = options.delete(:on)
        parsed_tag_list = parser.call(tags)

        return model.none if parsed_tag_list.empty?

        request = ::Metka::QueryBuilder.new.call(model, cols, parsed_tag_list, options)
        model.where(request)
      }

      base.class_eval do
        columns.each do |column|
          scope "with_all_#{column}",    ->(tags) { tagged_with(tags, on: [ column ]) }
          scope "with_any_#{column}",    ->(tags) { tagged_with(tags, on: [ column ], any: true) }
          scope "without_all_#{column}", ->(tags) { tagged_with(tags, on: [ column ], exclude: true) }
          scope "without_any_#{column}", ->(tags) { tagged_with(tags, on: [ column ], any: true, exclude: true) }
        end

        unless respond_to?(:tagged_with)
          scope :tagged_with, ->(tags = '', options = {}) {
            options[:join_operator] ||= ::Metka::OR
            options = {any: false}.merge(options)
            options[:on] ||= columns

            tagged_with_lambda.call(self, tags, **options)
          }
        end
      end

      base.define_singleton_method :metka_cloud do |*columns|
        return [] if columns.blank?

        prepared_unnest = columns.map { |column| "#{table_name}.#{column}" }.join(' || ')
        subquery = all.select("UNNEST(#{prepared_unnest}) AS tag_name")

        unscoped.from(subquery).group(:tag_name).pluck(:tag_name, 'COUNT(*) AS taggings_count')
      end

      columns.each do |column|
        base.define_method(column.singularize + '_list=') do |v|
          write_attribute(column, parser.call(v).to_a)
          write_attribute(column, nil) if send(column).empty?
        end

        base.define_method(column.singularize + '_list') do
          parser.call(send(column))
        end

        base.define_singleton_method :"#{column.singularize}_cloud" do
          metka_cloud(column)
        end
      end
    end
  end
end
