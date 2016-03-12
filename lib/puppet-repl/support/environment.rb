module PuppetRepl
  module Support
    module Environment
      # creates a puppet environment given a module path and environment name
      # this is cached
      def puppet_environment
        unless @puppet_environment
          do_initialize
          @puppet_environment = Puppet::Node::Environment.create(
          puppet_env_name,
          module_dirs,
          manifests_dir
          )
        end
        @puppet_environment
      end

      # the cached name of the environment
      def puppet_env_name
        @penv ||= ENV['PUPPET_ENV'] || Puppet[:environment]
      end

      # currently this is not being used
      def environment_loaders
        name = compiler.loaders.public_environment_loader.loader_name
      end

    end
  end
end
