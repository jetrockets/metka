# frozen_string_literal: true

require "arel"

module Metka
  OR = Arel::Nodes::Or
  AND = Arel::Nodes::And

  def self.Model(column: nil, columns: nil, **options)
    columns = [ column, *columns ].uniq.compact
    raise ArgumentError, "Columns not specified" unless columns.present?

    Metka::Model.new(columns: columns, **options)
  end

  class Model < Module
    def initialize(columns:, **options)
      @columns = columns.dup.freeze
      @options = options.dup.freeze
    end

    def included(base)
      define_column_scopes(base)
      define_tagged_with_scope(base)
      define_tag_clouds(base)
      define_tag_list_accessors(base)
    end

    private

    def define_column_scopes(base)
      @columns.each do |column|
        base.scope "with_all_#{column}", ->(tags) { tagged_with(tags, on: [ column ]) }
        base.scope "with_any_#{column}", ->(tags) { tagged_with(tags, on: [ column ], any: true) }
        base.scope "without_all_#{column}", ->(tags) { tagged_with(tags, on: [ column ], exclude: true) }
        base.scope "without_any_#{column}", ->(tags) { tagged_with(tags, on: [ column ], any: true, exclude: true) }
      end
    end

    # @param tags [Object] list of tags, representation depends on the parser used
    # @param options [Hash] options
    #   @option :any [Boolean] match any of the tags instead of all of them
    #   @option :exclude [Boolean] negate the match
    #   @option :join_operator [Metka::AND, Metka::OR] how to combine multiple columns
    #   @option :on [Array<String>] column names to search
    # @return [ActiveRecord::Relation]
    def define_tagged_with_scope(base)
      return if base.respond_to?(:tagged_with)

      columns = @columns
      parser = tag_parser

      base.scope :tagged_with, ->(tags = "", options = {}) {
        options = { any: false }.merge(options)
        options[:join_operator] ||= ::Metka::OR
        tag_columns = options.delete(:on) || columns

        tag_list = parser.call(tags)
        next self if tag_list.empty?

        where(::Metka::QueryBuilder.new.call(self, tag_columns, tag_list, options))
      }
    end

    def define_tag_clouds(base)
      base.define_singleton_method :metka_cloud do |*cloud_columns|
        return [] if cloud_columns.blank?

        prepared_unnest = cloud_columns.map { |column| "#{table_name}.#{column}" }.join(" || ")
        subquery = all.select("UNNEST(#{prepared_unnest}) AS tag_name")

        unscoped.from(subquery).group(:tag_name).pluck(:tag_name, Arel.sql("COUNT(*) AS taggings_count"))
      end

      @columns.each do |column|
        base.define_singleton_method(:"#{column.singularize}_cloud") { metka_cloud(column) }
      end
    end

    def define_tag_list_accessors(base)
      parser = tag_parser

      @columns.each do |column|
        base.define_method(:"#{column.singularize}_list=") do |tags|
          write_attribute(column, parser.call(tags).to_a)
          write_attribute(column, nil) if send(column).empty?
        end

        base.define_method(:"#{column.singularize}_list") do
          parser.call(send(column))
        end
      end
    end

    # Metka.config.parser is looked up on every call so that reconfiguring it
    # after a model has been included still takes effect.
    def tag_parser
      custom = @options[:parser]

      ->(tags) { (custom || Metka.config.parser.instance).call(tags) }
    end
  end
end
