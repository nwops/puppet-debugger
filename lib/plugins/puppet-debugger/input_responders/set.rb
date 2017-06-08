require 'puppet-debugger/input_responder_plugin'
module PuppetDebugger
  module InputResponders
    class Set < InputResponderPlugin
      COMMAND_WORDS = [':set']
      SUMMARY = 'Set the a puppet debugger config'
      COMMAND_GROUP = :scope

      def run(args = [])
        handle_set(input)
      end

      private

      def handle_set(input)
        output = ''
        args = input.split(' ')
        args.shift # throw away the set
        case args.shift
          when /node/
            if name = args.shift
              output = "Resetting to use node #{name}"
              debugger.handle_input('reset')
              debugger.set_remote_node_name(name)
            else
              debugger.out_buffer.puts 'Must supply a valid node name'
            end
          when /loglevel/
            if level = args.shift
              @log_level = level
              set_log_level(level)
              output = "loglevel #{Puppet::Util::Log.level} is set"
            end
        end
        output
      end

      def set_log_level(level)
        Puppet::Util::Log.level = level.to_sym
        buffer_log = Puppet::Util::Log.newdestination(:buffer)
        if buffer_log
          # if this is already set the buffer_log is nil
          buffer_log.out_buffer = out_buffer
          buffer_log.err_buffer = out_buffer
        end
        nil
      end
    end
  end
end
