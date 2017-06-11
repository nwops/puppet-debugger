require 'singleton'
require 'puppet-debugger/support/errors'
require 'forwardable'

module PuppetDebugger
    class InputResponderPlugin
      include Singleton
      extend Forwardable
      attr_accessor :debugger
      def_delegators :debugger, :scope, :node, :environment,
                     :add_hook, :handle_input, :delete_hook, :function_map
      def_delegators :scope, :compiler, :catalog
      def_delegators :node, :facts

      def self.command_words
        self::COMMAND_WORDS
      end

      def self.summary
        self::SUMMARY
      end

      def self.command_group
        self::COMMAND_GROUP
      end

      def self.details
        { words: command_words, summary: summary, group: command_group }
      end

      # @param args [Array[String]] - an array of arguments to pass to the plugin command
      # @param debugger PuppetDebugger::Cli  - an instance of the PuppetDebugger::Cli object
      # @return the output of the plugin command
      def self.execute(args = [], debugger)
        instance.debugger = debugger
        instance.run(args)
      end

      # @param args [Array[String]] - an array of arguments to pass to the plugin command
      # @return the output of the plugin command
      def run(args = [])
        raise NotImplementedError
      end
    end
end
