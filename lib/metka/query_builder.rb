# frozen_string_literal: true

require_relative 'query_builder/base_query'
require_relative 'query_builder/exclude_all_tags_query'
require_relative 'query_builder/exclude_any_tags_query'
require_relative 'query_builder/any_tags_query'
require_relative 'query_builder/all_tags_query'

module Metka
  class QueryBuilder
    def call(taggable_model, column, tag_list, options)
      if options[:exclude_all].present?
        ExcludeAllTagsQuery.instance.call(taggable_model, column, tag_list)
      elsif options[:exclude_any].present?
        ExcludeAnyTagsQuery.instance.call(taggable_model, column, tag_list)
      elsif options[:any].present?
        AnyTagsQuery.instance.call(taggable_model, column, tag_list)
      else
        AllTagsQuery.instance.call(taggable_model, column, tag_list)
      end
    end
  end
end
