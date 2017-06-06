require 'benchmark'
require 'singleton'
module PuppetDebugger
  module InputResponders
    class Benchmark
      COMMAND_WORDS = %w(benchmark bm)
      include Singleton
      attr_accessor :debugger

      def self.execute(args = [], debugger)
        instance.debugger = debugger
        instance.run(args)
      end

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
    end
  end
end