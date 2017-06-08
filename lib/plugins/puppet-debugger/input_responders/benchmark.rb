require 'benchmark'
require 'puppet-debugger/input_responder_plugin'
module PuppetDebugger
  module InputResponders
    class Benchmark < InputResponderPlugin
      COMMAND_WORDS = %w(benchmark bm)
      SUMMARY = 'Benchmark your Puppet code.'
      COMMAND_GROUP = :tools

      def run(args = [])
        if args.count > 0
          enable(false)
          out = debugger.handle_input(args.first)
          disable
          out
        else
          status = debugger.bench ? disable : enable(true)
          "Benchmark Mode #{status}"
        end
      end

      private

      def disable
        debugger.bench = false
        debugger.extra_prompt = ''
        'Off'
      end

      def enable(show_status = false)
        debugger.bench = true
        if show_status
          debugger.extra_prompt = 'BM'
          'On'
        end
      end

    end
  end
end