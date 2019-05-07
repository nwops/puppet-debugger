# frozen_string_literal: true

require 'puppet/pops'
require 'facterdb'
require 'tempfile'

# load all the generators found in the generators directory
Dir.glob(File.join(File.dirname(__FILE__), 'support', '*.rb')).each do |file|
  require_relative File.join('support', File.basename(file, '.rb'))
end

module PuppetDebugger
  module Support
    include PuppetDebugger::Support::Compilier
    include PuppetDebugger::Support::Environment
    include PuppetDebugger::Support::Facts
    include PuppetDebugger::Support::Scope
    include PuppetDebugger::Support::Node
    include PuppetDebugger::Support::Loader

    # parses the error type into a more useful error message defined in errors.rb
    # returns new error object or the original if error cannot be parsed
    def parse_error(error)
      case error
      when SocketError
        PuppetDebugger::Exception::ConnectError.new(message: "Unknown host: #{Puppet[:server]}")
      when Net::HTTPError
        PuppetDebugger::Exception::AuthError.new(message: error.message)
      when Errno::ECONNREFUSED
        PuppetDebugger::Exception::ConnectError.new(message: error.message)
      when Puppet::Error
        if error.message =~ /could\ not\ find\ class/i
          PuppetDebugger::Exception::NoClassError.new(default_modules_paths: default_modules_paths,
                                                      message: error.message)
        elsif error.message =~ /default\ node/i
          PuppetDebugger::Exception::NodeDefinitionError.new(default_site_manifest: default_site_manifest,
                                                             message: error.message)
        else
          error
        end
      else
        error
      end
    end

    def lib_dirs(module_dirs = modules_paths)
      dirs = module_dirs.map do |mod_dir|
        Dir["#{mod_dir}/*/lib"].entries
      end.flatten
      dirs + [puppet_debugger_lib_dir]
    end

    def static_responder_list
      PuppetDebugger::InputResponders::Commands.command_list
    end

    # returns either the module name or puppet version
    def mod_finder
      @mod_finder ||= Regexp.new('\/([\w\-\.]+)\/lib')
    end

    # this is the lib directory of this gem
    # in order to load any puppet functions from this gem we need to add the lib path
    # of this gem
    # @deprecated
    def puppet_debugger_lib_dir
      File.expand_path(File.join(File.dirname(File.dirname(File.dirname(__FILE__))), 'lib'))
    end

    def initialize_from_scope(value)
      set_scope(value)
      if value
        set_environment(value.environment)
        set_node(value.compiler.node) if defined?(value.compiler.node)
        set_compiler(value.compiler)
      end
    end

    def known_resource_types
      res = {
        hostclasses: scope.environment.known_resource_types.hostclasses.keys,
        definitions: scope.environment.known_resource_types.definitions.keys,
        nodes: scope.environment.known_resource_types.nodes.keys
      }
      if sites = scope.environment.known_resource_types.instance_variable_get(:@sites)
        res[:sites] = scope.environment.known_resource_types.instance_variable_get(:@sites).first
      end
      if scope.environment.known_resource_types.respond_to?(:applications)
        res[:applications] = scope.environment.known_resource_types.applications.keys
      end
      # some versions of puppet do not support capabilities
      if scope.environment.known_resource_types.respond_to?(:capability_mappings)
        res[:capability_mappings] = scope.environment.known_resource_types.capability_mappings.keys
      end
      res
    end

    # this is required in order to load things only when we need them
    def do_initialize
      Puppet.initialize_settings
      Puppet[:parser] = 'future' # this is required in order to work with puppet 3.8
      Puppet[:trusted_node_data] = true
    rescue ArgumentError => e
    rescue Puppet::DevError => e
      # do nothing otherwise calling init twice raises an error
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
      # should return nil or Puppet::Pops::Model::Program
      # puppet 5 does not have the method current
      model = parse_result.respond_to?(:current) ? parse_result.current : parse_result
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
      ::Puppet::Parser::AST::Hostclass.new('', code: ast_code)
    end

    # @param String - any valid puppet language code
    # @return Object - returns either a string of the result or object from puppet evaulation
    def puppet_eval(input)
      # in order to add functions to the scope the loaders must be created
      # in order to call native functions we need to set the global_scope
      ast = generate_ast(input)
      # record the input for puppet to retrieve and reference later
      file = Tempfile.new(['puppet_debugger_input', '.pp'])
      File.open(file, 'w') do |f|
        f.write(input)
      end
      Puppet.override({ current_environment: puppet_environment, code: input,
                        global_scope: scope, loaders: scope.compiler.loaders }, 'For puppet-debugger') do
        # because the repl is not a module we leave the modname blank
        scope.environment.known_resource_types.import_ast(ast, '')

        exec_hook :before_eval, '', self, self
        if bench
          result = nil
          time = Benchmark.realtime do
            result = parser.evaluate_string(scope, input, File.expand_path(file))
          end
          out = [result, "Time elapsed #{(time * 1000).round(2)} ms"]
        else
          out = parser.evaluate_string(scope, input, File.expand_path(file))
        end
        exec_hook :after_eval, out, self, self
        out
      end
    end

    def puppet_lib_dir
      # returns something like "/Library/Ruby/Gems/2.0.0/gems/puppet-4.2.2/lib/puppet.rb"
      # "/Users/adam/.rbenv/versions/2.2.6/lib/ruby/gems/2.2.0/gems/puppet-4.9.4/lib"

      # this is only useful when returning a namespace with the functions
      @puppet_lib_dir ||= File.dirname(Puppet.method(:[]).source_location.first)
    end

    # returns a future parser for evaluating code
    def parser
      @parser ||= ::Puppet::Pops::Parser::EvaluatingParser.new
    end
  end
end
