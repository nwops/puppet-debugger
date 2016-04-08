require 'tempfile'

module PuppetRepl
  module Support
    module Compilier
      def create_compiler(node)
        Puppet::Parser::Compiler.new(node)
      end

      def compiler
        @compiler
      end

      def set_compiler(value)
        @compiler = value
      end

    end
  end
end
