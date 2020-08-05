# frozen_string_literal: true

require 'puppet-debugger/input_responder_plugin'
module PuppetDebugger
  module InputResponders
    class Stacktrace < InputResponderPlugin
      COMMAND_WORDS = %w[stacktrace].freeze
      SUMMARY = 'Show the stacktrace for how we got here'
      COMMAND_GROUP = :tools

      # @return [Array]- returns a array of pp files that are involved in the stacktrace
      def run(_args = [])
        s = stacktrace
        s.empty? ? 'stacktrace not available'.warning : s.ai
      end

      # @return [Array] - an array of files with line numbers
      # @example
      # [
      #   "/nwops/puppetlabs-peadm/spec/fixtures/modules/peadm/plans/status.pp:23",
      #   "/nwops/puppetlabs-peadm/spec/fixtures/modules/peadm/plans/status.pp:20"
      # ]
      def stacktrace
        stack = Puppet::Pops::PuppetStack.stacktrace.find_all { |line| !line.include?('unknown') }
        stack.each_with_object([]) do |item, acc|
          acc << item.join(':')
        end
      end
    end
  end
end
