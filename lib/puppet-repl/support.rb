require 'puppet/pops'
require 'facterdb'

module PuppetRepl
  module Support

    # returns an array of module directories
    def module_dirs
      dirs = []
      dirs << File.join(Puppet[:environmentpath],puppet_env_name,'modules')
      dirs << Puppet.settings[:basemodulepath].split(':')
      dirs.flatten
    end

    # this is required in order to load things only when we need them
    def do_initialize
      begin
        Puppet.initialize_settings
      rescue
        # do nothing otherwise calling init twice raises an error
      end
    end

    def puppet_lib_dir
      # returns something like "/Library/Ruby/Gems/2.0.0/gems/puppet-4.2.2/lib/puppet.rb"
      @puppet_lib_dir ||= File.dirname(Puppet.method(:[]).source_location.first)
    end

    # returns a array of function files
    def function_files
      search_dirs = lib_dirs.map do |lib_dir|
        [File.join(lib_dir, 'puppet', 'functions', '**', '*.rb'),
          File.join(lib_dir, 'functions', '**', '*.rb'),
         File.join(lib_dir, 'puppet', 'parser', 'functions', '*.rb')
         ]
      end
      # add puppet lib directories
      search_dirs << [File.join(puppet_lib_dir, 'puppet', 'functions', '**', '*.rb'),
        File.join(puppet_lib_dir, 'puppet', 'parser', 'functions', '*.rb')
       ]
      Dir.glob(search_dirs.flatten)
    end

    # returns either the module name or puppet version
    def mod_finder
      @mod_finder ||= Regexp.new('\/([\w\-\.]+)\/lib')
    end

    # returns a map of functions
    def function_map
      unless @functions
        do_initialize
        @functions = {}
        function_files.each do |file|
          obj = {}
          name = File.basename(file, '.rb')
          obj[:name] = name
          obj[:parent] = mod_finder.match(file)[1]
          @functions["#{obj[:parent]}::#{name}"] = obj
        end
      end
      @functions
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
      Puppet::Parser::ParserFactory.evaluating_parser
      @parser || ::Puppet::Pops::Parser::EvaluatingParser.new
    end

    # the cached name of the environment
    def puppet_env_name
      @penv ||= ENV['PUPPET_ENV'] || Puppet[:environment]
    end

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

    # def functions
    #   @functions = []
    #   @functions << compiler.loaders.static_loader.loaded.keys.find_all {|l| l.type == :function}
    # end

    def environment_loaders
      name = compiler.loaders.public_environment_loader.loader_name
    end

    def compiler
      @compiler
    end

    def node
      @node ||= create_node
    end

    def create_scope
      @compiler = create_compiler(node) # creates a new compiler for each scope
      scope = Puppet::Parser::Scope.new(compiler)
      scope.source = Puppet::Resource::Type.new(:node, node.name)
      scope.parent = compiler.topscope
      load_lib_dirs
      compiler.compile # this will load everything into the scope
      scope
    end

    def create_compiler(node)
      Puppet::Parser::Compiler.new(node)
    end

    def facterdb_filter
      'operatingsystem=RedHat and operatingsystemrelease=/^7/ and architecture=x86_64 and facterversion=/^2.4\./'
    end

    # uses facterdb (cached facts) and retrives the facts given a filter
    def facts
      unless @facts
        @facts ||= FacterDB.get_facts(facterdb_filter).first
      end
      @facts
    end

    # creates a node object
    def create_node
      options = {}
      options[:parameters] = facts
      options[:facts] = facts
      options[:classes] = []
      options[:environment] = puppet_environment
      Puppet::Node.new(facts[:fqdn], options)
    end

    def scope
      unless @scope
        do_initialize
        @scope ||= create_scope
      end
      @scope
    end

    def manifests_dir
      File.join(Puppet[:environmentpath],puppet_env_name,'manifests')
    end

  end
end
#scope.environment.known_resource_types
