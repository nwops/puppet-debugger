require 'puppet-debugger/input_responder_plugin'
module PuppetDebugger
  module InputResponders
    class Vars < InputResponderPlugin
      COMMAND_WORDS = %w(vars ls)
      SUMMARY = 'List all the variables in the current scopes.'
      COMMAND_GROUP = :scope

      def run(args = [])
        # remove duplicate variables that are also in the facts hash
        variables = debugger.scope.to_hash.delete_if { |key, _value| debugger.node.facts.values.key?(key) }
        variables['facts'] = 'removed by the puppet-debugger' if variables.key?('facts')
        output = 'Facts were removed for easier viewing'.ai + "\n"
        output += variables.ai(sort_keys: true, indent: -1)
      end
    end
  end
end
