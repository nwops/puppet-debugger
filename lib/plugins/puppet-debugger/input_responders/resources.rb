require 'puppet-debugger/input_responder_plugin'
module PuppetDebugger
  module InputResponders
    class Resources < InputResponderPlugin
      COMMAND_WORDS = %w(resources)
      SUMMARY = 'List all the resources current in the catalog.'
      COMMAND_GROUP = :scope

      def run(args = [])
        res = debugger.catalog.resources.map do |res|
          res.to_s.gsub(/\[/, "['").gsub(/\]/, "']") # ensure the title has quotes
        end
        if !args.first.nil?
          res[args.first.to_i].ai
        else
          output = "Resources not shown in any specific order\n".warning
          output += res.ai
        end
      end
    end
  end
end
