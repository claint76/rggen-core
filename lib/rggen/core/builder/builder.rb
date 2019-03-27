# frozen_string_literal: true

module RgGen
  module Core
    module Builder
      class Builder
        def initialize
          @categories = Hash.new do |_, category_name|
            raise BuilderError.new("unknown category: #{category_name}")
          end
          @input_component_registries = Hash.new do |_, component_name|
            raise BuilderError.new("unknown component: #{component_name}")
          end
          @output_component_registries = {}
          initialize_categories
        end

        def input_component_registry(name, &body)
          component_registry(:input, name, body)
        end

        def output_component_registry(name, &body)
          component_registry(:output, name, body)
        end

        def register_loader(component, loader)
          @input_component_registries[component].register_loader(loader)
        end

        def register_loaders(component, loaders)
          @input_component_registries[component].register_loaders(loaders)
        end

        def define_loader(component, &body)
          @input_component_registries[component].define_loader(&body)
        end

        def add_feature_registry(name, target_category, registry)
          target_categories =
            if target_category
              Array(@categories[target_category])
            else
              @categories.values
            end
          target_categories.each do |category|
            category.add_feature_registry(name, registry)
          end
        end

        [
          :define_simple_feature,
          :define_list_feature,
          :define_list_item_feature
        ].each do |method_name|
          define_method(method_name) do |category, *args, &body|
            @categories[category].__send__(__method__, *args, &body)
          end
        end

        def enable(category, *args)
          @categories[category].enable(*args)
        end

        def build_input_component_factory(component)
          @input_component_registries[component].build_root_factory
        end

        def build_output_component_factories(exceptions)
          @output_component_registries
            .reject { |name, _| exceptions.include?(name) }
            .map { |_, registry| registry.build_root_factory }
        end

        def register_input_components
          Configuration.setup(self)
          RegisterMap.setup(self)
        end

        private

        def initialize_categories
          [
            :global, :register_map, :register_block, :register, :bit_field
          ].each do |category|
            @categories[category] = Category.new(category)
          end
        end

        def component_registry(type, name, body)
          registries, klass =
            case type
            when :input
              [@input_component_registries, InputComponentRegistry]
            when :output
              [@output_component_registries, OutputComponentRegistry]
            end
          registries.key?(name) || (registries[name] = klass.new(name, self))
          Docile.dsl_eval(registries[name], &body)
        end
      end
    end
  end
end
