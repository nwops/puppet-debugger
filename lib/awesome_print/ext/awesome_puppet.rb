module AwesomePrint
  module Puppet
    def self.included(base)
      base.send :alias_method, :cast_without_puppet_resource, :cast
      base.send :alias_method, :cast, :cast_with_puppet_resource
    end

    # this tells ap how to cast our object so we can be specific
    # about printing different puppet objects
    def cast_with_puppet_resource(object, type)
      cast = cast_without_puppet_resource(object, type)
      # check the object to see if it has an acestor (< ) of the specified type
      if (defined?(::Puppet::Type)) && (object.class < ::Puppet::Type)
        cast = :puppet_type
      elsif (defined?(::Puppet::Pops::Types)) && (object.class < ::Puppet::Pops::Types)
        cast = :puppet_type
      elsif (defined?(::Puppet::Parser::Resource)) && (object.class < ::Puppet::Parser::Resource)
        cast = :puppet_resource
      elsif /Puppet::Pops::Types/.match(object.class.to_s)
        cast = :puppet_type
      end
      cast
    end

    def awesome_puppet_resource(object)
      return '' if object.nil?
      awesome_puppet_type(object.to_ral)
    end

    def awesome_puppet_type(object)
      return '' if object.nil?
      return object.to_s unless object.respond_to?(:name)
      h = object.to_hash.merge(:name => object.name, :title => object.title)
      res_str = awesome_hash(h)
      "#{object.class} #{res_str.gsub(':', '')}"
    end
  end
end

AwesomePrint::Formatter.send(:include, AwesomePrint::Puppet)
