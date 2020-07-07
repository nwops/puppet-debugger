# frozen_string_literal: true

require 'puppet-debugger/input_responder_plugin'
module PuppetDebugger
  module InputResponders
    class Krt < InputResponderPlugin
      COMMAND_WORDS = %w[krt].freeze
      SUMMARY = 'List all the known resource types.'
      COMMAND_GROUP = :scope

      def run(_args = [])
        debugger.known_resource_types.ai(sort_keys: true, indent: -1)
      end
    end
  end
end
