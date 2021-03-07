# frozen_string_literal: true

require 'puppet-debugger/input_responder_plugin'
module PuppetDebugger
  module InputResponders
    class Exit < InputResponderPlugin
      COMMAND_WORDS = %w[exit].freeze
      SUMMARY = 'Quit Puppet Debugger, or use control-d'
      COMMAND_GROUP = :help

      def run(_args = [])
        exit 0
      end
    end
  end
end
