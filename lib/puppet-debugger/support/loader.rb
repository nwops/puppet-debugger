# frozen_string_literal: true

module PuppetDebugger
  module Support
    # the Loader module wraps a few puppet loader functions
    module Loader
      def create_loader(environment)
        Puppet::Pops::Loaders.new(environment)
      end

      def loaders
        @loaders ||= create_loader(puppet_environment)
      end

      # returns an array of module loaders that we may need to use in the future
      # in order to parse all types of code (ie. functions)  For now this is not
      # being used.
      # def resolve_paths(loaders)
      #   mod_resolver = loaders.instance_variable_get(:@module_resolver)
      #   all_mods = mod_resolver.instance_variable_get(:@all_module_loaders)
      #   all_mods.last.get_contents
      # end

      # def functions
      #   @functions = []
      #   @functions << compiler.loaders.static_loader.loaded.keys.find_all {|l| l.type == :function}
      # returns all the type names, athough we cannot determine the difference between datatype and resource type
      # loaders.static_loader.loaded.map { |item| item.first.name}
      # loaders.implementation_registry.
      #     instance_variable_get(:'@implementations_per_type_name').
      #     keys.find_all { |t| t !~ /::/ }
      # Puppet::Pops::Types::TypeFactory.type_map.keys.map(&:capatilize)
      # end
      # Puppet::Pops::Adapters::LoaderAdapter.loader_for_model_object(generate_ast(''))
    end
  end
end
