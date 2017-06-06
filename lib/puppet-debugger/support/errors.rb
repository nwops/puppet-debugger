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

    class ConnectError < Error
      def message
        out = <<-EOF
#{data[:message]}
EOF
      end
    end

    class BadFilter < FatalError
      def message
        data[:message]
      end
    end

    class UndefinedNode < FatalError
      def message
        out = <<-EOF
Cannot find node with name: #{data[:name]} on remote server
    EOF
      end
    end

    class TimeOutError < Error
      # Errno::ETIMEDOUT
    end

    class NoClassError < FatalError
      def message
        out = <<-EOF
#{data[:message]}
You are missing puppet classes that are required for compilation.
Please ensure these classes are installed on this machine in any of the following paths:
#{data[:default_modules_paths]}
EOF
      end
    end

    class NodeDefinitionError < FatalError
      def message
        out = <<-EOF
You are missing a default node definition in your site.pp that is required for compilation.
Please ensure you have at least the following default node definition
  node default {
    # include classes here
  }
in your #{data[:default_site_manifest]} file.
EOF
        out.fatal
      end
    end

    class AuthError < FatalError
      def message
        out = <<-EOF
#{data[:message]}
You will need to edit your auth.conf or conf.d/auth.conf (puppetserver) to allow node calls.
EOF
    end
    end
  end
end
