# frozen_string_literal: true

module PuppetDebugger
  module Support
    BASE_DIR = File.dirname(File.dirname(__FILE__))
    module InputResponders

      def static_responder_list
        %w[exit facterdb_filter reset ] +  PuppetDebugger::InputResponders::Commands.command_list
      end

      # displays the facterdb filter
      # @param [Array] - args is not used
      def facterdb_filter(_args = [])
        dynamic_facterdb_filter.ai
      end

      def handle_set(input)
        output = ''
        args = input.split(' ')
        args.shift # throw away the set
        case args.shift
        when /node/
          if name = args.shift
            output = "Resetting to use node #{name}"
            reset
            set_remote_node_name(name)
          else
            out_buffer.puts 'Must supply a valid node name'
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

      def environment(_args = [])
        "Puppet Environment: #{puppet_env_name}"
      end

      def reset(_args = [])
        set_scope(nil)
        set_remote_node_name(nil)
        set_node(nil)
        set_facts(nil)
        set_environment(nil)
        set_compiler(nil)
        set_log_level(log_level)
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
