require 'puppet-debugger/input_responder_plugin'
module PuppetDebugger
  module InputResponders
    class FacterdbFilter < InputResponderPlugin
      COMMAND_WORDS = %w(facterdb_filter ff)
      SUMMARY = 'Set the facterdb filter'
      COMMAND_GROUP = :node

      # displays the facterdb filter
      # @param [Array] - args is not used
      def run(args = [])
        debugger.dynamic_facterdb_filter.ai
      end
    end
  end
end
