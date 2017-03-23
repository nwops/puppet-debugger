module PuppetDebugger
  module Support
    module Loader

      def create_loader(environment)
        Puppet::Pops::Loaders.new(environment)
      end

      def data_types
        loader.implementation_registry.
            instance_variable_get(:'@implementations_per_type_name').
            keys.find_all { |t| t !~ /::/ }
      end

      def loaders
        @loaders ||= create_loader(puppet_environment)
      end

      # returns an array of module loaders that we may need to use in the future
      # in order to parse all types of code (ie. functions)  For now this is not
      # being used.
      def resolve_paths(loaders)
        mod_resolver = loaders.instance_variable_get(:@module_resolver)
        all_mods = mod_resolver.instance_variable_get(:@all_module_loaders)
      end

      # def functions
      #   @functions = []
      #   @functions << compiler.loaders.static_loader.loaded.keys.find_all {|l| l.type == :function}
      # end

    end
  end
end
