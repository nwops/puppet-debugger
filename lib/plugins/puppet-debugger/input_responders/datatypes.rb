# frozen_string_literal: true

require 'puppet-debugger/input_responder_plugin'
module PuppetDebugger
  module InputResponders
    class Datatypes < InputResponderPlugin
      COMMAND_WORDS = %w[datatypes].freeze
      SUMMARY = 'List all the datatypes available in the environment.'
      COMMAND_GROUP = :environment

      def run(args = [])
        filter = args
        datatypes = find_datatypes(all_data_types.sort, filter)
        datatypes.ai
      end

      def find_datatypes(datatypes, filter = [])
        return datatypes if filter.nil? || filter.empty?

        filter_string = filter.join(' ').downcase
        datatypes.find_all do |datatype|
          datatype.downcase.include?(filter_string)
        end
      end

      # @return [Array[String]] - returns a list of all the custom data types found in all the modules in the environment
      def environment_data_types
        globs = debugger.puppet_environment.instance_variable_get(:@modulepath).map { |m| File.join(m, '**', 'types', '**', '*.pp') }
        files = globs.map { |g| Dir.glob(g) }.flatten
        files.map do |f|
          m = File.read(f).match(/type\s([a-z\d\:_]+)/i)
          next if m =~ /type|alias/ # can't figure out the best way to filter type and alias out

          m[1] if m && m[1] =~ /::/
        end.uniq.compact
      end

      # @return [Array[String]] - a list of core data types
      def core_datatypes
        loaders.implementation_registry
               .instance_variable_get(:'@implementations_per_type_name')
               .keys.find_all { |t| t !~ /::/ }
      end

      # @return [Array[String]] - combined list of core data types and environment data types
      def all_data_types
        unless loaders.respond_to?(:implementation_registry)
          Puppet.info("Data Types Not Available in Puppet: #{Puppet.version}")
          return []
        end
        core_datatypes + environment_data_types
      end
    end
  end
end
