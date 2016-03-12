module PuppetRepl
  module Support
    module Scope
      def create_scope(node)
        @compiler = create_compiler(node) # creates a new compiler for each scope
        scope = Puppet::Parser::Scope.new(@compiler)
        scope.source = Puppet::Resource::Type.new(:node, node.name)
        scope.parent = @compiler.topscope
        load_lib_dirs
        # compiling will load all the facts into the scope
        # without this step facts will not get resolved
        scope.compiler.compile # this will load everything into the scope
        scope
      end

      # returns a hash of varaibles that are currently in scope
      def scope_vars
        vars = scope.to_hash.delete_if {| key, value | node.facts.key?(key.to_sym) }
        vars['facts'] = 'removed by the puppet-repl'
      end
    end
  end
end
