require 'puppet-debugger/input_responder_plugin'
module PuppetDebugger
  module InputResponders
    class Classification < InputResponderPlugin
      COMMAND_WORDS = %w(classification)
      SUMMARY = 'Show the classification details of the node.'
      COMMAND_GROUP = :node

      def run(_args = [])
        debugger.node.classes.ai
      end
    end
  end
end
