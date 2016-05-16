require 'puppet/indirector/node/rest'

module PuppetRepl
  module Support
    module Node
      # creates a node object using defaults or gets the remote node
      # object if the remote_node_name is defined
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
          node_obj.add_server_facts(server_facts)
          node_obj
        end
        node_obj
      end

      def set_remote_node_name(name)
        @remote_node_name = name
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
        remote_node = indirection.find(name, :environment => puppet_environment)
        remote_node
      end

      # this is a hack to get around that the puppet node fact face does not return
      # a proper node object with the facts hash populated
      # returns a node object with a proper facts hash
      def convert_remote_node(remote_node)
        options = {}
        # remove trusted data as it will later get populated during compilation
        parameters = remote_node.parameters.dup
        trusted_data = parameters.delete('trusted')
        options[:parameters] = parameters || {}
        options[:facts] = Puppet::Node::Facts.new(remote_node.name,remote_node.parameters)
        options[:classes] = remote_node.classes
        options[:environment] = puppet_environment
        node_object = Puppet::Node.new(remote_node.name, options)
        node_object.add_server_facts(server_facts)
        node_object.trusted_data = trusted_data
        node_object
      end

      # query the remote puppet server and retrieve the node object
      #
      def set_node_from_name(name)
        out_buffer.puts ("Fetching node #{name}")
        remote_node = get_remote_node(name)
        if remote_node and remote_node.parameters.empty?
          remote_node_name = nil  # clear out the remote name
          raise PuppetRepl::Exception::UndefinedNode.new(:name => remote_node.name)
        end
        remote_node_name = remote_node.name
        node_object = convert_remote_node(remote_node)
        set_node(node_object)
      end

      def set_node(value)
        @node = value
      end
    end
  end
end
