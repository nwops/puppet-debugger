require 'puppet/pops'
require 'facterdb'
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

    def known_resource_types
      res = {
        :hostclasses => scope.known_resource_types.hostclasses.keys,
        :definitions => scope.known_resource_types.definitions.keys,
        :nodes => scope.known_resource_types.nodes.keys,
      }
      if sites = scope.known_resource_types.instance_variable_get(:@sites)
        res.merge!(:sites => scope.known_resource_types.instance_variable_get(:@sites).first)
      end
      if scope.known_resource_types.respond_to?(:applications)
        res.merge!(:applications => scope.known_resource_types.applications.keys)
      end
      # some versions of puppet do not support capabilities
      if scope.known_resource_types.respond_to?(:capability_mappings)
        res.merge!(:capability_mappings => scope.known_resource_types.capability_mappings.keys)
      end
      res
    end

    # this is required in order to load things only when we need them
    def do_initialize
      begin
        Puppet.initialize_settings
        Puppet[:trusted_node_data] = true
      rescue
        # do nothing otherwise calling init twice raises an error
      end
    end

    def puppet_lib_dir
      # returns something like "/Library/Ruby/Gems/2.0.0/gems/puppet-4.2.2/lib/puppet.rb"
      # this is only useful when returning a namespace with the functions
      @puppet_lib_dir ||= File.dirname(Puppet.method(:[]).source_location.first)
    end

    # returns a future parser for evaluating code
    def parser
      @parser || ::Puppet::Pops::Parser::EvaluatingParser.new
    end

    def default_manifests_dir
      File.join(Puppet[:environmentpath],default_puppet_env_name,'manifests')
    end

    def default_site_manifest
      File.join(default_manifests_dir, 'site.pp')
    end

  end
end
