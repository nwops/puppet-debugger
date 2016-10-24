require 'puppet/pops'
require 'facterdb'
require 'tempfile'

# load all the generators found in the generators directory
Dir.glob(File.join(File.dirname(__FILE__),'support', '*.rb')).each do |file|
  require_relative File.join('support', File.basename(file, '.rb'))
end

module PuppetRepl
  module Support
    include PuppetRepl::Support::Compilier
    include PuppetRepl::Support::Environment
    include PuppetRepl::Support::Facts
    include PuppetRepl::Support::Scope
    include PuppetRepl::Support::Functions
    include PuppetRepl::Support::Node
    include PuppetRepl::Support::InputResponders
    include PuppetRepl::Support::Play

    # parses the error type into a more useful error message defined in errors.rb
    # returns new error object or the original if error cannot be parsed
    def parse_error(error)
      case error
      when SocketError
        PuppetRepl::Exception::ConnectError.new(:message => "Unknown host: #{Puppet[:server]}")
      when Net::HTTPError
        PuppetRepl::Exception::AuthError.new(:message => error.message)
      when Errno::ECONNREFUSED
        PuppetRepl::Exception::ConnectError.new(:message => error.message)
      when Puppet::Error
        if error.message =~ /could\ not\ find\ class/i
          PuppetRepl::Exception::NoClassError.new(:default_modules_paths => default_modules_paths,
           :message => error.message)
        elsif error.message =~ /default\ node/i
          PuppetRepl::Exception::NodeDefinitionError.new(:default_site_manifest => default_site_manifest,
           :message => error.message)
        else
          error
        end
      else
        error
      end
    end

    # returns an array of module directories, generally this is the only place
    # to look for puppet code by default.  This is read from the puppet configuration
    def default_modules_paths
      dirs = []
      do_initialize if Puppet[:codedir].nil?
      # add the puppet-repl directory so we can load any defined functions
      dirs << File.join(Puppet[:environmentpath],default_puppet_env_name,'modules') unless Puppet[:environmentpath].empty?
      dirs << Puppet.settings[:basemodulepath].split(':')
      dirs.flatten
    end

    # this is the lib directory of this gem
    # in order to load any puppet functions from this gem we need to add the lib path
    # of this gem
    def puppet_repl_lib_dir
      File.expand_path(File.join(File.dirname(File.dirname(File.dirname(__FILE__))), 'lib'))
    end

    # returns all the modules paths defined in the environment
    def modules_paths
      puppet_environment.full_modulepath
    end

    def initialize_from_scope(value)
      set_scope(value)
      unless value.nil?
        set_environment(value.environment)
        set_node(value.compiler.node)
        set_compiler(value.compiler)
      end
    end

     def keyword_expression
       @keyword_expression ||= Regexp.new(/^exit|^:set|^play|^classification|^facts|^vars|^functions|^classes|^resources|^krt|^environment|^reset|^help/)
     end

    def known_resource_types
      res = {
        :hostclasses => scope.environment.known_resource_types.hostclasses.keys,
        :definitions => scope.environment.known_resource_types.definitions.keys,
        :nodes => scope.environment.known_resource_types.nodes.keys,
      }
      if sites = scope.environment.known_resource_types.instance_variable_get(:@sites)
        res.merge!(:sites => scope.environment.known_resource_types.instance_variable_get(:@sites).first)
      end
      if scope.environment.known_resource_types.respond_to?(:applications)
        res.merge!(:applications => scope.environment.known_resource_types.applications.keys)
      end
      # some versions of puppet do not support capabilities
      if scope.environment.known_resource_types.respond_to?(:capability_mappings)
        res.merge!(:capability_mappings => scope.environment.known_resource_types.capability_mappings.keys)
      end
      res
    end

    # this is required in order to load things only when we need them
    def do_initialize
      begin
        Puppet.initialize_settings
        Puppet[:parser] = 'future'  # this is required in order to work with puppet 3.8
        Puppet[:trusted_node_data] = true
      rescue ArgumentError => e

      rescue Puppet::DevError => e
        # do nothing otherwise calling init twice raises an error
      end
    end

    # @param String - any valid puppet language code
    # @return Hostclass - a puppet Program object which is considered the main class
    def generate_ast(string = nil)
      parse_result = parser.parse_string(string, '')
      # the parse_result may be
      # * empty / nil (no input)
      # * a Model::Program
      # * a Model::Expression
      #
      model = parse_result.nil? ? nil : parse_result.current
      args = {}
      ::Puppet::Pops::Model::AstTransformer.new('').merge_location(args, model)

      ast_code =
      if model.is_a? ::Puppet::Pops::Model::Program
        ::Puppet::Parser::AST::PopsBridge::Program.new(model, args)
      else
        args[:value] = model
        ::Puppet::Parser::AST::PopsBridge::Expression.new(args)
      end
      # Create the "main" class for the content - this content will get merged with all other "main" content
      ::Puppet::Parser::AST::Hostclass.new('', :code => ast_code)
    end

    # @param String - any valid puppet language code
    # @return Object - returns either a string of the result or object from puppet evaulation
    def puppet_eval(input)
      # in order to add functions to the scope the loaders must be created
      # in order to call native functions we need to set the global_scope
      ast = generate_ast(input)
      # record the input for puppet to retrieve and reference later
      file = Tempfile.new(['puppet_repl_input', '.pp'])
      File.open(file, 'w') do |f|
        f.write(input)
      end
      Puppet.override( {:code => input, :global_scope => scope, :loaders => scope.compiler.loaders } , 'For puppet-repl') do
         # because the repl is not a module we leave the modname blank
         scope.environment.known_resource_types.import_ast(ast, '')
         parser.evaluate_string(scope, input, File.expand_path(file))
      end
    end

    def puppet_lib_dir
      # returns something like "/Library/Ruby/Gems/2.0.0/gems/puppet-4.2.2/lib/puppet.rb"
      # this is only useful when returning a namespace with the functions
      @puppet_lib_dir ||= File.dirname(Puppet.method(:[]).source_location.first)
    end

    # returns a future parser for evaluating code
    def parser
      @parser ||= ::Puppet::Pops::Parser::EvaluatingParser.new
    end

    def default_manifests_dir
      File.join(Puppet[:environmentpath],default_puppet_env_name,'manifests')
    end

    def default_site_manifest
      File.join(default_manifests_dir, 'site.pp')
    end

  end
end
