# frozen_string_literal: true

require 'puppet/indirector/node/rest'

module PuppetDebugger
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
          name = default_facts.values['fqdn']
          node_obj = Puppet::Node.new(name, options)
          node_obj.add_server_facts(server_facts) if node_obj.respond_to?(:add_server_facts)
          node_obj
        end
        node_obj
      end

      def create_real_node(environment)
        node = nil
        unless Puppet[:node_name_fact].empty?
          # Collect our facts.
          facts = Puppet::Node::Facts.indirection.find(Puppet[:node_name_value])
          raise "Could not find facts for #{Puppet[:node_name_value]}" unless facts

          Puppet[:node_name_value] = facts.values[Puppet[:node_name_fact]]
          facts.name = Puppet[:node_name_value]
        end
        Puppet.override({ current_environment: environment }, 'For puppet debugger') do
          # Find our Node
          node = Puppet::Node.indirection.find(Puppet[:node_name_value])
          raise "Could not find node #{Puppet[:node_name_value]}" unless node

          # Merge in the facts.
          node.merge(facts.values) if facts
        end
        node
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
        indirection.find(name, environment: puppet_environment)
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
        options[:facts] = Puppet::Node::Facts.new(remote_node.name, remote_node.parameters)
        options[:classes] = remote_node.classes
        options[:environment] = puppet_environment
        node_object = Puppet::Node.new(remote_node.name, options)
        node_object.add_server_facts(server_facts) if node_object.respond_to?(:add_server_facts)
        node_object.trusted_data = trusted_data
        node_object
      end

      # query the remote puppet server and retrieve the node object
      #
      def set_node_from_name(name)
        out_buffer.puts "Fetching node #{name}"
        remote_node = get_remote_node(name)
        if remote_node && remote_node.parameters.empty?
          remote_node_name = nil # clear out the remote name
          raise PuppetDebugger::Exception::UndefinedNode, name: remote_node.name
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
