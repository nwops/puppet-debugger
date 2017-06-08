require 'puppet-debugger/input_responder_plugin'
module PuppetDebugger
  module InputResponders
    class Facts < InputResponderPlugin
      COMMAND_WORDS = %w(facts)
      SUMMARY = 'List all the facts associated with the node.'
      COMMAND_GROUP = :node

      def run(args = [])
        variables = debugger.node.facts.values
        variables.ai(sort_keys: true, indent: -1)
      end
    end
  end
end
