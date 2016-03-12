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

    # returns an array of module directories
    def module_dirs
      dirs = []
      do_initialize if Puppet[:codedir].nil?
      dirs << File.join(Puppet[:environmentpath],puppet_env_name,'modules') unless Puppet[:environmentpath].empty?
      dirs << Puppet.settings[:basemodulepath].split(':')
      dirs.flatten
    end

    def known_resource_types
      {
        :hostclasses => scope.known_resource_types.hostclasses.keys,
        :definitions => scope.known_resource_types.definitions.keys,
        :nodes => scope.known_resource_types.nodes.keys,
        :capability_mappings => scope.known_resource_types.capability_mappings.keys,
        :applications => scope.known_resource_types.applications.keys,
        :site => scope.known_resource_types.instance_variable_get(:@sites)[0] # todo, could be just a binary, this dumps the entire body (good while developing)
      }
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

    # returns either the module name or puppet version
    def mod_finder
      @mod_finder ||= Regexp.new('\/([\w\-\.]+)\/lib')
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

    def compiler
      @compiler
    end

    # @return [node] puppet node object
    def node
      @node ||= create_node
    end

    # @return [Scope] puppet scope object
    def scope
      unless @scope
        do_initialize
        @scope ||= create_scope(node)
      end
      @scope
    end

    def manifests_dir
      File.join(Puppet[:environmentpath],puppet_env_name,'manifests')
    end

  end
end
