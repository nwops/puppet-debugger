require 'puppet/indirector/node/rest'

module PuppetRepl
  module Support
    module Node
      # creates a node object
      def create_node
        if remote_node_name
          # refetch
          node_obj = set_node_from_name(remote_node_name)
        end
        unless node_obj
          options = {}
          options[:parameters] = default_facts.values
          options[:facts] = default_facts
          options[:classes] = []
          options[:environment] = puppet_environment
          node_obj = Puppet::Node.new(default_facts.values['fqdn'], options)
        end
        node_obj
      end

      def remote_node_name=(name)
        @remote_node_name = name
      end

      def remote_node_name
        @remote_node_name
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
        if node_object && node_object.parameters
          # remove trusted data as it will later get populated during compilation
          node_object.trusted_data = node_object.parameters.delete('trusted')
          remote_node_name = node_object.name
          set_node(node_object)
        else
          out_buffer.puts "Remote node with name #{name} was not found, using defaults"
          remote_node_name = nil  # clear out the remote name
        end
      end

      def set_node(value)
        @node = value
      end
    end
  end
end
