require 'tempfile'

module PuppetRepl
  module Support
    module Compilier
      def create_compiler(node)
        Puppet::Parser::Compiler.new(node)
      end
    end
  end
end
