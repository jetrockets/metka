# frozen_string_literal: true

require "arel"

module Metka
  def self.Model(column: nil, columns: nil, **options)
    columns = [ column, *columns ].uniq.compact
    raise ArgumentError, "Columns not specified" unless columns.present?

    Metka::Model.new(columns: columns, **options)
  end

  class Model < Module
    TAGGED_WITH_OPTIONS = %i[any exclude join_operator on].freeze

    def initialize(columns:, **options)
      @columns = columns.dup.freeze
      @options = options.dup.freeze

      unknown = index_tables.keys - @columns
      if unknown.any?
        raise ArgumentError, "index_tables declared for unknown columns #{unknown.inspect}, expected #{@columns.inspect}"
      end
    end

    def included(base)
      define_column_scopes(base)
      define_tagged_with_scope(base)
      define_index_tables(base)
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
      allowed = TAGGED_WITH_OPTIONS

      # legacy_options carries the positional hash callers could pass before
      # these became keywords. Ruby 3 will not convert one into keywords, so
      # accepting it explicitly keeps `tagged_with(tags, options)` working.
      base.scope :tagged_with, ->(tags = "", legacy_options = nil, **options) {
        options = legacy_options.to_h.symbolize_keys.merge(options)
        unknown = options.keys - allowed
        if unknown.any?
          raise ArgumentError, "Unknown tagged_with options #{unknown.inspect}, expected #{allowed.inspect}"
        end

        tag_list = parser.call(tags)
        next self if tag_list.empty?

        where(::Metka::QueryBuilder.instance.call(self, options[:on] || columns, tag_list, {
          any: options.fetch(:any, false),
          exclude: options[:exclude],
          join_operator: options[:join_operator] || ::Metka::OR
        }))
      }
    end

    # The index strategy (`rails g metka:strategies:index`) maintains a
    # (tag_name, record_id) side table per tagged column. Declaring it here
    # via `index_tables: { "tags" => "posts_tags_index" }` lets the SQLite
    # query path answer from that table instead of scanning json_each.
    def define_index_tables(base)
      tables = index_tables

      base.define_singleton_method(:metka_index_table) { |column| tables[column.to_s] }
    end

    def define_tag_clouds(base)
      taggable = @columns

      # metka_cloud is public and its arguments land in raw SQL, so they are
      # checked against the declared columns rather than interpolated on trust.
      base.define_singleton_method :metka_cloud do |*cloud_columns|
        return [] if cloud_columns.blank?

        cloud_columns = cloud_columns.map(&:to_s)
        unknown = cloud_columns - taggable
        if unknown.any?
          raise ArgumentError, "Unknown tag columns #{unknown.inspect}, expected #{taggable.inspect}"
        end

        quoted = cloud_columns.map { |column|
          connection.quote_table_name("#{table_name}.#{column}")
        }

        subquery =
          if connection.adapter_name.match?(/sqlite/i)
            # SQLite has no UNNEST; json_each unpacks each JSON array as a
            # lateral cross join. Arrays cannot be concatenated the way
            # PostgreSQL concatenates them, so multiple columns become one
            # SELECT per column glued with UNION ALL — a NULL column joins to
            # zero rows either way, matching UNNEST of a NULL array.
            parts = quoted.map { |column|
              all.select("json_each.value AS tag_name").joins("CROSS JOIN json_each(#{column})").to_sql
            }
            Arel.sql("(#{parts.join(" UNION ALL ")}) subquery")
          else
            all.select("UNNEST(#{quoted.join(" || ")}) AS tag_name")
          end

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

    def index_tables
      (@options[:index_tables] || {}).transform_keys(&:to_s).transform_values(&:to_s).freeze
    end

    # Metka.config.parser is looked up on every call so that reconfiguring it
    # after a model has been included still takes effect.
    def tag_parser
      custom = @options[:parser]

      ->(tags) { (custom || Metka.config.parser.instance).call(tags) }
    end
  end
end
