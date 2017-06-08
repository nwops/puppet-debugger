require 'puppet-debugger/input_responder_plugin'
module PuppetDebugger
  module InputResponders
    class Whereami < InputResponderPlugin
      COMMAND_WORDS = %w(whereami)
      SUMMARY = 'Show code surrounding the current context.'
      COMMAND_GROUP = :context

      # source_file and source_line_num instance variables must be set for this
      # method to show the surrounding code
      # @return [String] - string output of the code surrounded by the breakpoint or nil if file
      # or line_num do not exist
      def run(args = [])
        file = debugger.source_file
        line_num = debugger.source_line_num
        if file && line_num
          if file == :code
            source_code = Puppet[:code]
            code = DebuggerCode.from_string(source_code, :puppet)
          else
            code = DebuggerCode.from_file(file, :puppet)
          end
          return code.with_marker(line_num).around(line_num, 5)
                     .with_line_numbers.with_indentation(5).with_file_reference.to_s
        end
      end
    end
  end
end
