# frozen_string_literal: true

module PuppetDebugger
  module Support
    module Scope
      # @param [Puppet::Pops::Scope] - Scope object or nil
      def set_scope(value)
        @scope = value
      end

      # @return [Puppet::Pops::Scope] - returns a puppet scope object
      def scope
        @scope ||= create_scope
      end

      # @return [Puppet::Pops::Scope] - returns a puppet scope object
      def create_scope
        do_initialize
        begin
          # creates a new compiler for each scope
          scope = Puppet::Parser::Scope.new(compiler)
          # creates a node class
          scope.source = Puppet::Resource::Type.new(:node, node.name)
          scope.parent = compiler.topscope
          # compiling will load all the facts into the scope
          # without this step facts will not get resolved
          scope.compiler.compile # this will load everything into the scope
        rescue StandardError => e
          err = parse_error(e)
          raise err
        end
        scope
      end

      # @return [Hash] - returns a hash of variables that are currently in scope
      def scope_vars
        vars = scope.to_hash.delete_if { |key, _value| node.facts.values.key?(key.to_sym) }
        vars['facts'] = 'removed by the puppet-debugger'
      end
    end
  end
end
