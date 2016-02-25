module PuppetRepl
  module Support

    # returns an array of module directories
    def module_dirs
      dirs = []
      dirs << File.join(Puppet[:environmentpath],puppet_env_name,'modules')
      dirs << Puppet.settings[:basemodulepath].split(':')
      dirs.flatten
    end

    def function_files
      lib_dirs.map do |lib_dir|
        [Dir.glob(File.join(lib_dir, 'puppet', 'functions', '*.rb')),
           Dir.glob(File.join(lib_dir, 'puppet', 'parser', 'functions', '*.rb')) ]
      end.flatten
    end

    def lib_dirs
      module_dirs.map do |mod_dir|
        Dir["#{mod_dir}/*/lib"].entries
      end.flatten
    end

    def load_lib_dirs
      lib_dirs.each do |lib|
        $LOAD_PATH << lib
      end
    end

    # returns a future parser for evaluating code
    def parser
      @parser || ::Puppet::Pops::Parser::EvaluatingParser.new
    end

    def puppet_env_name
      @penv ||= ENV['PUPPET_ENV'] || 'prepl'
    end

    # creates a puppet environment given a module path and environment name
    # this is cached
    def puppet_environment
      @puppet_environment ||= Puppet::Node::Environment.create(
        puppet_env_name,
        module_dirs,
        manifests_dir
        )
    end

    def create_scope(node_name)
      #options['parameters']
      #options['facts']
      #options[:classes]
      node = create_node(node_name)
      compiler = create_compiler(node)
      scope = Puppet::Parser::Scope.new(compiler)
      scope.source = Puppet::Resource::Type.new(:node, node_name)
      scope.parent = compiler.topscope
      load_lib_dirs
      scope
    end

    def create_compiler(node)
      Puppet::Parser::Compiler.new(node)
    end

    def create_node(node_name)
      Puppet::Node.new(node_name, :environment => puppet_environment)
    end

    def scope
      begin
        Puppet.initialize_settings
      rescue
        # do nothing otherwise calling init twice raises an error
      end
      @scope ||= create_scope('node_name')
    end

    def manifests_dir
      File.join(Puppet[:environmentpath],puppet_env_name,'manifests')
    end

    def build_node(name, opts = {})
      opts.merge!({:environment => node_environment})
      Puppet::Node.new(name, opts)
    end

  end
end
#scope.environment.known_resource_types
