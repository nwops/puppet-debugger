module PuppetDebugger
  module Support
    module Loader

      def create_loader(environment)
        Puppet::Pops::Loaders.new(environment)
      end

      # @return [Array[String]] - returns a list of all the custom data types found in all the modules in the environment
      def environment_data_types
        files = Dir.glob(puppet_environment.modulepath.map {|m| File.join(m, '**', 'types', '**', '*.pp')})
        t = files.map do |f|
          m = File.read(f).match(/type\s([a-z\d\:_]+)/i)
          next if m =~ /type|alias/  # can't figure out the best way to filter type and alias out
          m[1] if m and m[1] =~ /::/
        end.uniq.compact
      end

      # @return [Array[String]] - a list of core data types
      def core_datatypes
        loaders.implementation_registry.
            instance_variable_get(:'@implementations_per_type_name').
            keys.find_all { |t| t !~ /::/ }
      end

      # @return [Array[String]] - combined list of core data types and environment data types
      def all_data_types
        unless loaders.respond_to?(:implementation_registry)
          Puppet.info("Data Types Not Available in Puppet: #{Puppet.version}")
          return []
        end
        core_datatypes + environment_data_types
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
      #Puppet::Pops::Types::TypeFactory.type_map.keys.map(&:capatilize)
      # end
      #Puppet::Pops::Adapters::LoaderAdapter.loader_for_model_object(generate_ast(''))

    end
  end
end
