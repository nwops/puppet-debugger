require 'puppet-debugger/input_responder_plugin'
module PuppetDebugger
  module InputResponders
    class Functions < InputResponderPlugin
      COMMAND_WORDS = %w(functions)
      SUMMARY = 'List all the functions available in the environment.'
      COMMAND_GROUP = :environment

      def run(args = [])
        filter = args.first || ''
        function_map.keys.sort.grep(/^#{Regexp.escape(filter)}/)
      end
    end
  end
end
