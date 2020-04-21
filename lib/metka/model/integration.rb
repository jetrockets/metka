# frozen_string_literal: true

module Metka
  module Model
    class Integration
      def initialize(owner_class)
        @owner_class = owner_class
      end

      def integrate!(&block)
        instance_eval(&block) if block_given?
      end

      def column(column_name, **options)
        parser = options[:parser] || Metka.config.parser.instance

        add_scopes_to_owner!(column_name, search_by_tags_method_for(column_name, parser))
        add_list_methods_to_owner!(column_name, parser)
      end

      private

      def search_by_tags_method_for(column_name, parser)
        ->(model, tags, **options) {
          parsed_tag_list = parser.call(tags)

          if options[:without].present?
            model.where.not(::Metka::QueryBuilder.new.call(model, column_name, parsed_tag_list, options))
          else
            return model.none if parsed_tag_list.empty?
            model.where(::Metka::QueryBuilder.new.call(model, column_name, parsed_tag_list, options))
          end
        }
      end

      def add_scopes_to_owner!(column_name, search_method)
        @owner_class.class_eval do
          scope "with_all_#{column_name}",    ->(tags) { search_method.call(self, tags) }
          scope "with_any_#{column_name}",    ->(tags) { search_method.call(self, tags, { any: true }) }
          scope "without_all_#{column_name}", ->(tags) { search_method.call(self, tags, { exclude_all: true, without: true }) }
          scope "without_any_#{column_name}", ->(tags) { search_method.call(self, tags, { exclude_any: true, without: true }) }
        end
      end

      def add_list_methods_to_owner!(column_name, parser)
        @owner_class.define_method(:"#{column_name.to_s.singularize}_list=") do |v|
          self.write_attribute(column_name, parser.call(v).to_a)
          self.write_attribute(column_name, nil) if self.send(column_name).empty?
        end

        @owner_class.define_method(:"#{column_name.to_s.singularize}_list") do
          parser.call(self.send(column_name))
        end
      end
    end
  end
end
