# frozen_string_literal: true

require 'puppet-debugger/input_responder_plugin'
module PuppetDebugger
  module InputResponders
    class Classes < InputResponderPlugin
      COMMAND_WORDS = %w[classes].freeze
      SUMMARY = 'List all the classes current in the catalog.'
      COMMAND_GROUP = :scope

      def run(args = [])
        filter = args
        classes = find_classes(debugger.catalog.classes, filter)
        classes.ai
      end

      def find_classes(classes, filter = [])
        return classes if filter.nil? || filter.empty?

        filter_string = filter.join(' ').downcase
        classes.find_all do |klass|
          klass.downcase.include?(filter_string)
        end
      end
    end
  end
end
