# frozen_string_literal: true
require 'tempfile'

module PuppetDebugger
  module Support
    module Compilier
      def create_compiler(node)
        Puppet::Parser::Compiler.new(node)
      end

      def compiler
        @compiler ||= create_compiler(node)
      end

      def set_compiler(value)
        @compiler = value
      end
    end
  end
end
