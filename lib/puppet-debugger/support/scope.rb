# frozen_string_literal: true

module PuppetDebugger
  module Support
    module Scope
      # @param [Puppet::Pops::Scope] - Scope object or nil
      def set_scope(value)
        @scope = value
      end

      def catalog
        @catalog || scope.compiler.catalog
      end

      def get_catalog_text(c)
        return nil unless c

        Puppet::FileSystem.read(c, :encoding => 'utf-8')
      end

      def set_catalog(catalog_file)
        return unless catalog_file

        catalog_text = get_catalog_text(catalog_file)
        scope # required
        Puppet.override({ :current_environment => environment }, _("For puppet debugger")) do
          format = Puppet::Resource::Catalog.default_format
          begin
            c = Puppet::Resource::Catalog.convert_from(format, catalog_text)
          rescue => detail
            raise Puppet::Error, _("Could not deserialize catalog from %{format}: %{detail}") % { format: format, detail: detail }, detail.backtrace
          end
          # Resolve all deferred values and replace them / mutate the catalog
          # Puppet 6 only
          Puppet::Pops::Evaluator::DeferredResolver.resolve_and_replace(node.facts, c) if Gem::Version.new(Puppet.version) >= Gem::Version.new('6.0.0')
          @catalog = c
        end
      end

      # @return [Puppet::Pops::Scope] - returns a puppet scope object
      def scope
        @scope ||= create_scope
      end

      # @return [Puppet::Pops::Scope] - returns a puppet scope object
      def create_scope
        do_initialize
        begin
          # creates a new compiler for each scope
          scope = Puppet::Parser::Scope.new(compiler)
          # creates a node class
          scope.source = Puppet::Resource::Type.new(:node, node.name)
          scope.parent = compiler.topscope
          # compiling will load all the facts into the scope
          # without this step facts will not get resolved
          scope.compiler.compile # this will load everything into the scope
        rescue StandardError => e
          err = parse_error(e)
          raise err
        end
        scope
      end

      # @return [Hash] - returns a hash of variables that are currently in scope
      def scope_vars
        vars = scope.to_hash.delete_if { |key, _value| node.facts.values.key?(key.to_sym) }
        vars['facts'] = 'removed by the puppet-debugger'
      end
    end
  end
end
