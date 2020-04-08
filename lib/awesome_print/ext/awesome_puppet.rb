# frozen_string_literal: true

module Kernel
  class Hash
    def to_h
      hash = extra_hash_attributes.dup

      self.class.hash_attribute_names.each do |name|
        hash[name] = __send__(name)
      end

      hash
    end
  end
end

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
      if defined?(::Puppet::Type) && (object.class < ::Puppet::Type)
        cast = :puppet_type
      elsif defined?(::Puppet::Pops::Types) && (object.class < ::Puppet::Pops::Types)
        cast = :puppet_type
      elsif defined?(::Puppet::Parser::Resource) && (object.class < ::Puppet::Parser::Resource)
        cast = :puppet_resource
      elsif /Puppet::Pops::Types/.match(object.class.to_s)
        cast = :puppet_type
      elsif /Bolt::/.match(object.class.to_s)
        cast = :bolt_type
      end
      cast
    end

    def awesome_bolt_type(object)
      if object.class.to_s.include?('Result')
        object.to_data.ai
      elsif object.is_a?(::Bolt::Target)
        object.to_h.merge(object.detail).ai
      else
        object.ai
      end
    end

    def awesome_puppet_resource(object)
      return '' if object.nil?
      resource_object = object.to_ral
      awesome_puppet_type(resource_object)
    end

    def awesome_puppet_type(object)
      return '' if object.nil?
      return object.to_s unless object.respond_to?(:name) && object.respond_to?(:title) && object.respond_to?(:to_hash)
      if Array.new.respond_to?(:to_h)
        # to_h is only supported in ruby 2.1+
        h = object.to_hash.merge(name: object.name, title: object.title).sort.to_h
      else
        h = object.to_hash.merge(name: object.name, title: object.title)
      end
      res_str = awesome_hash(JSON.parse(h.to_json)) #converting to json removes symbols
      "#{object.class} #{res_str}"
    end
  end
end

AwesomePrint::Formatter.send(:include, AwesomePrint::Puppet)
