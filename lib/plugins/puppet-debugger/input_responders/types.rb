require 'puppet-debugger/input_responder_plugin'
module PuppetDebugger
  module InputResponders
    class Datatypes < InputResponderPlugin
      COMMAND_WORDS = %w(datatypes)
      SUMMARY = 'List all the datatypes available in the environment.'
      COMMAND_GROUP = :environment

      def run(args = [])
        types = debugger.all_data_types
        return types.sort.ai if types.instance_of?(Array)
        types
      end

    end
  end
end
