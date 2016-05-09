module PuppetRepl
  module Support
    module Environment
      # creates a puppet environment given a module path and environment name
      # this is cached
      def puppet_environment
        @puppet_environment ||= create_environment
      end

      def create_environment
        @puppet_environment = Puppet::Node::Environment.create(
          default_puppet_env_name,
          default_modules_paths,
          default_manifests_dir
        )
      end

      def set_environment(value)
        @puppet_environment = value
      end

      def puppet_env_name
        puppet_environment.name
      end

      # the cached name of the environment
      def default_puppet_env_name
         ENV['PUPPET_ENV'] || Puppet[:environment]
      end

      # currently this is not being used
      def environment_loaders
        name = compiler.loaders.public_environment_loader.loader_name
      end

    end
  end
end
