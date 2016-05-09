require 'puppet/indirector/node/rest'

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

      def get_remote_node(name)
        indirection = Puppet::Indirector::Indirection.instance(:node)
        indirection.terminus_class = 'rest'
        indirection.find(name, :environment => puppet_environment)
      end

      def set_node_from_name(name)
        out_buffer.puts ("Fetching node #{name}")
        node_object = get_remote_node(name)
        # remove trusted data as it will later get populated during compilation
        node_object.trusted_data = node_object.parameters.delete('trusted')
        set_node(node_object)
      end

      def set_node(value)
        @node = value
      end
    end
  end
end
