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

      # @return [Array[String]] an array of words the user can call the command with
      def self.command_words
        self::COMMAND_WORDS
      end

      # @return [String] a summary of the plugin
      def self.summary
        self::SUMMARY
      end

      # @return [String] the name of the command group the plugin is in
      def self.command_group
        self::COMMAND_GROUP
      end

      # @return [Hash] a has of all the details of the plugin
      def self.details
        { words: command_words, summary: summary, group: command_group }
      end

      # @param buffer_words [Array[String]] a array of words the user has typed in
      # @return Array[String] - an array of words that will help the user with word completion
      # By default this returns an empty array, your plugin can chose to override this method in order to
      # provide the user with a list of key words based on the user's input
      def self.command_completion(buffer_words)
        []
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
