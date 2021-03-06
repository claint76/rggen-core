# frozen_string_literal: true

require 'docile'
require 'erubi'
require 'fileutils'
require 'forwardable'
require 'json'
require 'optparse'
require 'pathname'
require 'singleton'
require 'yaml'

require_relative 'core/version'

require_relative 'core/facets'
require_relative 'core/core_extensions/object'

require_relative 'core/utility/attribute_setter'
require_relative 'core/utility/code_utility/line'
require_relative 'core/utility/code_utility/code_block'
require_relative 'core/utility/code_utility/source_file'
require_relative 'core/utility/code_utility/structure_definition'
require_relative 'core/utility/code_utility'
require_relative 'core/utility/error_utility'
require_relative 'core/utility/regexp_patterns'

require_relative 'core/exceptions'

require_relative 'core/base/proxy_call'
require_relative 'core/base/internal_struct'
require_relative 'core/base/shared_context'
require_relative 'core/base/component'
require_relative 'core/base/component_factory'
require_relative 'core/base/feature'
require_relative 'core/base/feature_factory'
require_relative 'core/base/hierarchical_accessors'
require_relative 'core/base/hierarchical_feature_accessors'

require_relative 'core/input_base/input_value'
require_relative 'core/input_base/input_data'
require_relative 'core/input_base/loader'
require_relative 'core/input_base/json_loader'
require_relative 'core/input_base/yaml_loader'
require_relative 'core/input_base/component'
require_relative 'core/input_base/component_factory'
require_relative 'core/input_base/input_matcher'
require_relative 'core/input_base/verifier'
require_relative 'core/input_base/property'
require_relative 'core/input_base/feature'
require_relative 'core/input_base/feature_factory'

require_relative 'core/configuration/error'
require_relative 'core/configuration/component'
require_relative 'core/configuration/component_factory'
require_relative 'core/configuration/feature'
require_relative 'core/configuration/feature_factory'
require_relative 'core/configuration/loader'
require_relative 'core/configuration/ruby_loader'
require_relative 'core/configuration/hash_loader'
require_relative 'core/configuration/json_loader'
require_relative 'core/configuration/yaml_loader'
require_relative 'core/configuration'

require_relative 'core/register_map/input_data'
require_relative 'core/register_map/error'
require_relative 'core/register_map/component'
require_relative 'core/register_map/component_factory'
require_relative 'core/register_map/feature'
require_relative 'core/register_map/feature_factory'
require_relative 'core/register_map/loader'
require_relative 'core/register_map/ruby_loader'
require_relative 'core/register_map/hash_loader'
require_relative 'core/register_map/json_loader'
require_relative 'core/register_map/yaml_loader'
require_relative 'core/register_map'

require_relative 'core/output_base/template_engine'
require_relative 'core/output_base/erb_engine'
require_relative 'core/output_base/code_generator'
require_relative 'core/output_base/file_writer'
require_relative 'core/output_base/raise_error'
require_relative 'core/output_base/component'
require_relative 'core/output_base/component_factory'
require_relative 'core/output_base/feature'
require_relative 'core/output_base/feature_factory'

require_relative 'core/builder/component_entry'
require_relative 'core/builder/component_registry'
require_relative 'core/builder/input_component_registry'
require_relative 'core/builder/output_component_registry'
require_relative 'core/builder/simple_feature_entry'
require_relative 'core/builder/list_feature_entry'
require_relative 'core/builder/feature_registry'
require_relative 'core/builder/category'
require_relative 'core/builder/plugins'
require_relative 'core/builder/builder'
require_relative 'core/builder'

require_relative 'core/printers'
require_relative 'core/options'
require_relative 'core/dsl'
require_relative 'core/generator'
require_relative 'core/cli'
