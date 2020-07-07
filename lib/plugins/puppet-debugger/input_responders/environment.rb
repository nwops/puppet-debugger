# frozen_string_literal: true

require 'puppet-debugger/input_responder_plugin'
module PuppetDebugger
  module InputResponders
    class Environment < InputResponderPlugin
      COMMAND_WORDS = %w[environment].freeze
      SUMMARY = 'Show the current environment name'
      COMMAND_GROUP = :context

      def run(_args = [])
        "Puppet Environment: #{debugger.puppet_env_name}"
      end
    end
  end
end
