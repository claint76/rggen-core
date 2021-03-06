# frozen_string_literal: true

module RgGen
  module Core
    module Builder
      class FeatureRegistry
        def initialize(base_feature, factory)
          @base_feature = base_feature
          @factory = factory
          @feature_entries = {}
          @enabled_features = {}
        end

        def define_simple_feature(names, context = nil, &body)
          Array(names)
            .each { |name| create_new_entry(:simple, name, context, body) }
        end

        def define_list_feature(list_names, context = nil, &body)
          Array(list_names)
            .each { |name| create_new_entry(:list, name, context, body) }
        end

        def define_list_item_feature(list_name, feature_names, context = nil, &body)
          entry = @feature_entries[list_name]
          entry&.match_entry_type?(:list) ||
            (raise BuilderError.new("unknown list feature: #{list_name}"))
          Array(feature_names)
            .each { |name| entry.define_feature(name, context, &body) }
        end

        def enable(feature_or_list_names, feature_names = nil)
          if feature_names
            @enabled_features[feature_or_list_names]
              &.merge!(Array(feature_names))
          else
            Array(feature_or_list_names).each do |name|
              @enabled_features[name] ||= []
            end
          end
        end

        def enabled_features(list_name = nil)
          if list_name
            @enabled_features[list_name] || []
          else
            @enabled_features.keys
          end
        end

        def disable(feature_or_list_names = nil, feature_names = nil)
          if feature_names
            @enabled_features[feature_or_list_names]
              &.delete_if { |key, _| Array(feature_names).include?(key) }
          elsif feature_or_list_names
            Array(feature_or_list_names)
              .each(&@enabled_features.method(:delete))
          else
            @enabled_features.clear
          end
        end

        def delete(feature_or_list_names = nil, feature_names = nil)
          if feature_names
            @feature_entries[feature_or_list_names]&.delete(feature_names)
          elsif feature_or_list_names
            Array(feature_or_list_names)
              .each(&@feature_entries.method(:delete))
          else
            @feature_entries.clear
          end
        end

        def simple_feature?(feature_name)
          enabled_feature?(feature_name, :simple)
        end

        def list_feature?(list_name, feature_name = nil)
          return false unless enabled_feature?(list_name, :list)
          return true unless feature_name
          enabled_list_item_feature?(list_name, feature_name)
        end

        def feature?(feature_or_list_name, feature_name = nil)
          if feature_name
            list_feature?(feature_or_list_name, feature_name)
          else
            simple_feature?(feature_or_list_name) ||
              list_feature?(feature_or_list_name)
          end
        end

        def build_factories
          @enabled_features
            .select { |n, _| @feature_entries.key?(n) }
            .map { |n, f| [n, @feature_entries[n].build_factory(f)] }
            .to_h
        end

        private

        FEATURE_ENTRIES = {
          simple: SimpleFeatureEntry, list: ListFeatureEntry
        }.freeze

        def create_new_entry(type, name, context, body)
          entry = FEATURE_ENTRIES[type].new(self, name)
          entry.setup(@base_feature, @factory, context, body)
          @feature_entries[name] = entry
        end

        def enabled_feature?(name, entry_type)
          return false unless @feature_entries[name]
                                &.match_entry_type?(entry_type)
          @enabled_features.key?(name)
        end

        def enabled_list_item_feature?(list_name, feature_name)
          return false unless @feature_entries[list_name]
                                .feature?(feature_name)
          @enabled_features[list_name].include?(feature_name)
        end
      end
    end
  end
end
