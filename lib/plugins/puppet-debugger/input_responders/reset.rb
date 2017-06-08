require 'puppet-debugger/input_responder_plugin'
module PuppetDebugger
  module InputResponders
    class Reset < InputResponderPlugin
      COMMAND_WORDS = %w(reset)
      SUMMARY = 'Reset the debugger to a clean state.'
      COMMAND_GROUP = :context

      def run(args = [])
        debugger.set_scope(nil)
        debugger.set_remote_node_name(nil)
        debugger.set_node(nil)
        debugger.set_facts(nil)
        debugger.set_environment(nil)
        debugger.set_compiler(nil)
        debugger.set_log_level(debugger.log_level)
      end
    end
  end
end
