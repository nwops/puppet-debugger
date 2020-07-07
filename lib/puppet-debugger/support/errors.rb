# frozen_string_literal: true

module PuppetDebugger
  module Exception
    class Error < StandardError
      attr_accessor :data
      def initialize(data = {})
        @data = data
      end
    end

    class FatalError < Error
    end

    class InvalidCommand < Error
      def message
        data[:message]
      end
    end

    class ConnectError < Error
      def message
        <<~OUT
          #{data[:message]}
        OUT
      end
    end

    class BadFilter < FatalError
      def message
        data[:message]
      end
    end

    class UndefinedNode < FatalError
      def message
        <<~OUT
          Cannot find node with name: #{data[:name]} on remote server
        OUT
      end
    end

    class TimeOutError < Error
      # Errno::ETIMEDOUT
    end

    class NoClassError < FatalError
      def message
        <<~OUT
          #{data[:message]}
          You are missing puppet classes that are required for compilation.
          Please ensure these classes are installed on this machine in any of the following paths:
          #{data[:default_modules_paths]}
        OUT
      end
    end

    class NodeDefinitionError < FatalError
      def message
        out = <<~OUT
          You are missing a default node definition in your site.pp that is required for compilation.
          Please ensure you have at least the following default node definition
            node default {
              # include classes here
            }
          in your #{data[:default_site_manifest]} file.
        OUT
        out.fatal
      end
    end

    class AuthError < FatalError
      def message
        <<~OUT
          #{data[:message]}
          You will need to edit your auth.conf or conf.d/auth.conf (puppetserver) to allow node calls.
        OUT
      end
    end
  end
end
