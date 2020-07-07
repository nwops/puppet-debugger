# frozen_string_literal: true

require 'puppet-debugger/input_responder_plugin'
module PuppetDebugger
  module InputResponders
    class Resources < InputResponderPlugin
      COMMAND_WORDS = %w[resources].freeze
      SUMMARY = 'List all the resources current in the catalog.'
      COMMAND_GROUP = :scope

      def run(args = [])
        filter = args
        resources = find_resources(debugger.catalog.resources, filter)
        modified = resources.map do |res|
          res.to_s.gsub(/\[/, "['").gsub(/\]/, "']") # ensure the title has quotes
        end
        output = "Resources not shown in any specific order\n".warning
        output + modified.ai
      end

      def find_resources(resources, filter = [])
        return resources if filter.nil? || filter.empty?

        filter_string = filter.join(' ').downcase
        resources.find_all do |resource|
          resource.name.to_s.downcase.include?(filter_string) || resource.type.to_s.downcase.include?(filter_string)
        end
      end
    end
  end
end
