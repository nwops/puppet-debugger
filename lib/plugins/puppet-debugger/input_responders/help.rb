# frozen_string_literal: true

require 'puppet-debugger/input_responder_plugin'
module PuppetDebugger
  module InputResponders
    class Help < InputResponderPlugin
      COMMAND_WORDS = %w[help].freeze
      SUMMARY = 'Show the help screen with version information.'
      COMMAND_GROUP = :help

      def run(_args = [])
        PuppetDebugger::Cli.print_repl_desc
      end
    end
  end
end
