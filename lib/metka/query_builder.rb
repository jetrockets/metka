# frozen_string_literal: true

require_relative 'query_builder/exclude_tags_query'
require_relative 'query_builder/any_tags_query'
require_relative 'query_builder/all_tags_query'

module Metka
  class QueryBuilder
    def call(taggable_model, column, tag_list, options)
      if options[:exclude].present?
        ExcludeTagsQuery.new(taggable_model, tag_model, tagging_model, tag_list, options).build
      elsif options[:any].present?
        AnyTagsQuery.instance.(taggable_model, column, tag_list)
      else
        AllTagsQuery.instance.(taggable_model, column, tag_list)
      end
    end
  end
end