module PuppetDebugger
  module Support
    module Scope
      def set_scope(value)
        @scope = value
      end

      # @return [Scope] puppet scope object
      def scope
        unless @scope
          @scope ||= create_scope
        end
        @scope
      end

      def create_scope
        do_initialize
        begin
          @compiler = create_compiler(node) # creates a new compiler for each scope
          scope = Puppet::Parser::Scope.new(@compiler)
          # creates a node class
          scope.source = Puppet::Resource::Type.new(:node, node.name)
          scope.parent = @compiler.topscope
          load_lib_dirs
          # compiling will load all the facts into the scope
          # without this step facts will not get resolved
          scope.compiler.compile # this will load everything into the scope
        rescue StandardError => e
          err = parse_error(e)
          raise err
        end
        scope
      end

      # returns a hash of varaibles that are currently in scope
      def scope_vars
        vars = scope.to_hash.delete_if {| key, value | node.facts.values.key?(key.to_sym) }
        vars['facts'] = 'removed by the puppet-debugger'
      end
    end
  end
end
