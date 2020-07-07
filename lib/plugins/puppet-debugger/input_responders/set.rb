# frozen_string_literal: true

require 'puppet-debugger/input_responder_plugin'
module PuppetDebugger
  module InputResponders
    class Set < InputResponderPlugin
      COMMAND_WORDS = %w[set :set].freeze
      SUMMARY = 'Set the a puppet debugger config'
      COMMAND_GROUP = :scope
      KEYWORDS = %w[node loglevel].freeze
      LOGLEVELS = %w[debug info].freeze

      def self.command_completion(buffer_words)
        next_word = buffer_words.shift
        case next_word
        when 'loglevel'
          if buffer_words.count.positive?
            LOGLEVELS.grep(/^#{Regexp.escape(buffer_words.first)}/)
          else
            LOGLEVELS
          end
        when 'debug', 'info', 'node'
          []
        when nil
          %w[node loglevel]
        else
          KEYWORDS.grep(/^#{Regexp.escape(next_word)}/)
        end
      end

      def run(args = [])
        handle_set(args)
      end

      private

      def handle_set(input)
        output = ''
        # args = input.split(' ')
        # args.shift # throw away the set
        case input.shift
        when /node/
          if name = input.shift
            output = "Resetting to use node #{name}"
            debugger.set_scope(nil)
            debugger.set_node(nil)
            debugger.set_facts(nil)
            debugger.set_environment(nil)
            debugger.set_compiler(nil)
            set_log_level(debugger.log_level)
            debugger.set_remote_node_name(name)
          else
            debugger.out_buffer.puts 'Must supply a valid node name'
          end
        when /loglevel/
          if level = input.shift
            set_log_level(level)
            output = "loglevel #{Puppet::Util::Log.level} is set"
          end
        end
        output
      end

      def set_log_level(level)
        debugger.log_level = level
        Puppet::Util::Log.level = level.to_sym
        buffer_log = Puppet::Util::Log.newdestination(:buffer)
        if buffer_log
          # if this is already set the buffer_log is nil
          buffer_log.out_buffer = debugger.out_buffer
          buffer_log.err_buffer = debugger.out_buffer
        end
        nil
      end
    end
  end
end
