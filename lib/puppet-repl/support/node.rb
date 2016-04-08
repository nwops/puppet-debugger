module PuppetRepl
  module Support
    module Node
      # creates a node object
      def create_node
        options = {}
        options[:parameters] = default_facts.values
        options[:facts] = default_facts
        options[:classes] = []
        options[:environment] = puppet_environment
        Puppet::Node.new(default_facts.values['fqdn'], options)
      end

      # @return [node] puppet node object
      def node
        @node ||= create_node
      end

      def set_node(value)
        @node = value
      end
    end
  end
end
