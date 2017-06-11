require 'puppet-debugger/input_responder_plugin'
module PuppetDebugger
  module InputResponders
    class Types < InputResponderPlugin
      COMMAND_WORDS = %w(types)
      SUMMARY = 'List all the types available in the environment.'
      COMMAND_GROUP = :environment

      # @return - returns a list of types available to the environment
      # if a error occurs we we run the types function again
      def run(args = [])
        types
      end

      def types
        loaded_types = []
        begin
          # this loads all the types, if already loaded the file is skipped
          Puppet::Type.loadall
          Puppet::Type.eachtype do |t|
            next if t.name == :component
            loaded_types << t.name.to_s
          end
          loaded_types.ai
        rescue Puppet::Error => e
          puts e.message.red
          Puppet.info(e.message)
          # prevent more than two calls and recursive loop
          return if caller_locations(1, 10).find_all { |f| f.label == 'types' }.count > 2
          types
        end
      end
    end
  end
end
