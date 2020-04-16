require 'puppet-debugger/input_responder_plugin'
module PuppetDebugger
  module InputResponders
    class Classes < InputResponderPlugin
      COMMAND_WORDS = %w(classes)
      SUMMARY = 'List all the classes current in the catalog.'
      COMMAND_GROUP = :scope

      def run(args = [])
        debugger.catalog.classes.ai
      end

    end
  end
end
