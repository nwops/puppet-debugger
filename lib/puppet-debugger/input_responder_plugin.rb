require 'singleton'

module PuppetDebugger
    class InputResponderPlugin
      include Singleton
      attr_accessor :debugger

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

      def self.execute(args = [], debugger)
        instance.debugger = debugger
        instance.run(args)
      end

      def run(args = [])
        raise NotImplementedError
      end
    end
end
