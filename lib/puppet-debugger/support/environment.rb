# frozen_string_literal: true
module PuppetDebugger
  module Support
    module Environment
      # creates a puppet environment given a module path and environment name
      # this is cached
      def puppet_environment
        @puppet_environment ||= create_environment
      end

      # returns an array of module directories, generally this is the only place
      # to look for puppet code by default.  This is read from the puppet configuration
      def default_modules_paths
        dirs = []
        # add the puppet-debugger directory so we can load any defined functions
        dirs << File.join(Puppet[:environmentpath], default_puppet_env_name, 'modules') unless Puppet[:environmentpath].empty?
        dirs << Puppet.settings[:basemodulepath].split(File::PATH_SEPARATOR)
        dirs.flatten
      end

      # returns all the modules paths defined in the environment
      def modules_paths
        puppet_environment.full_modulepath
      end

      def default_manifests_dir
        File.join(Puppet[:environmentpath], Puppet[:environment], 'manifests')
      end

      def default_site_manifest
        File.join(default_manifests_dir, 'site.pp')
      end

      # returns the environment
      def create_environment
        Puppet::Node::Environment.create(Puppet[:environment],
                                         default_modules_paths,
                                         default_manifests_dir)
      end

      def create_node_environment(manifest = nil)
        env = Puppet.lookup(:current_environment)
        manifest ? env.override_with(manifest: manifest) : env
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
