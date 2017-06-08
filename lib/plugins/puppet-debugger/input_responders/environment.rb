require 'puppet-debugger/input_responder_plugin'
module PuppetDebugger
  module InputResponders
    class Environment < InputResponderPlugin
      COMMAND_WORDS = %w(environment)
      SUMMARY = 'Show the current environment name'
      COMMAND_GROUP = :context

      def run(args = [])
        "Puppet Environment: #{debugger.puppet_env_name}"
      end
    end
  end
end
