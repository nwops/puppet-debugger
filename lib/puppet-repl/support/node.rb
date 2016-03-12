module PuppetRepl
  module Support
    module Node
      # creates a node object
      def create_node
        options = {}
        options[:parameters] = facts
        options[:facts] = facts
        options[:classes] = []
        options[:environment] = puppet_environment
        Puppet::Node.new(facts[:fqdn], options)
      end
    end
  end
end
