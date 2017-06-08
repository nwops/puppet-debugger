require 'puppet-debugger/input_responder_plugin'
module PuppetDebugger
  module InputResponders
    class Exit < InputResponderPlugin
      COMMAND_WORDS = %w(exit)
      SUMMARY = 'Quit Puppet Debugger.'
      COMMAND_GROUP = :help

      def run(args = [])
        exit 0
      end
    end
  end
end
