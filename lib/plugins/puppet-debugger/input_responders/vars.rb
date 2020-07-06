require 'puppet-debugger/input_responder_plugin'
module PuppetDebugger
  module InputResponders
    class Vars < InputResponderPlugin
      COMMAND_WORDS = %w(vars ls)
      SUMMARY = 'List all the variables in the current scopes.'
      COMMAND_GROUP = :scope

      def run(args = [])
        filter = args
        unless filter.empty?
          parameters = resource_parameters(debugger.catalog.resources, filter)
          return parameters.ai(sort_keys: true, indent: -1)
        end
        # remove duplicate variables that are also in the facts hash
        variables = debugger.scope.to_hash.delete_if { |key, _value| debugger.node.facts.values.key?(key) }
        variables['facts'] = 'removed by the puppet-debugger' if variables.key?('facts')
        output = 'Facts were removed for easier viewing'.ai + "\n"
        output + variables.ai(sort_keys: true, indent: -1)
      end

      def resource_parameters(resources, filter = [])
        find_resources(resources, filter).each_with_object({}) do |resource, acc|
          name = "#{resource.type}[#{resource.name}]"
          acc[name] = parameters_to_h(resource)
          acc
        end
      end

      def parameters_to_h(resource)
        resource.parameters.each_with_object({}) do |param, params|
          name = param.first.to_s
          params[name] = param.last.respond_to?(:value) ? param.last.value : param.last
          params
        end
      end

      def find_resources(resources, filter = [])
        filter_string = filter.join(' ').downcase
        resources.find_all do |resource|
          resource.name.to_s.downcase.include?(filter_string) || resource.type.to_s.downcase.include?(filter_string)
        end
      end
    end
  end
end
