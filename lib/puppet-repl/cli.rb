require 'puppet'
require 'readline'
require 'json'
require_relative 'support'

module PuppetRepl
  class Cli
    include PuppetRepl::Support

    attr_accessor :settings

    def ap_formatter
      unless @ap_formatter
        inspector = AwesomePrint::Inspector.new({:sort_keys => true, :indent => 2})
        @ap_formatter = AwesomePrint::Formatter.new(inspector)
      end
      @ap_formatter
    end

    def puppet_eval(input)
      parser.evaluate_string(scope, input)
    end

    def to_resource_declaration(type)
      res = scope.catalog.resource(type.type_name, type.title)
      res.to_ral
    end

    # ruturns a formatted array
    def expand_resource_type(types)
      output = [types].flatten.map do |t|
        if t.class.to_s == 'Puppet::Pops::Types::PResourceType'
          to_resource_declaration(t)
        else
          t
        end
      end
      output
    end

    def normalize_output(result)
      if result.instance_of?(Array)
        output = expand_resource_type(result)
        if output.count == 1
          return output.first
        end
        return output
      end
      result
    end

    def handle_set(input)
      args = input.split(' ')
      args.shift # throw away the set
      case args.shift
      when /loglevel/
        if level = args.shift
          Puppet::Util::Log.level = level.to_sym
          Puppet::Util::Log.newdestination(:console)
          puts "loglevel #{Puppet::Util::Log.level} is set"
        end
      end
    end

    def handle_input(input)
      case input
      when 'help'
        PuppetRepl::Cli.print_repl_desc
      when 'functions'
        puts function_map.keys.sort
      when /^:set/
        handle_set(input)
      when 'facts'
        vars = Hash[ node.facts.map { |k, v| [k.to_s, v] } ]
        ap(vars, {:sort_keys => true, :indent => -1})
      when '_'
        puts(" => #{@last_item}")
      when 'vars'
        vars = scope.to_hash.delete_if {| key, value | node.facts.key?(key.to_sym) }
        vars['facts'] = 'removed by the puppet-repl'
        ap 'Facts were removed for easier viewing'
        ap(vars, {:sort_keys => true, :indent => -1})
      when 'environment'
        puts "Puppet Environment: #{puppet_env_name}"
      when 'vars'
        ap(scope.to_hash, {:sort_keys => true, :indent => 0})
      when 'exit'
        exit 0
      when 'reset'
        @scope = nil
      when 'krt'
        ap(known_resource_types, {:sort_keys => true, :indent => -1})
      else
        begin
          print " => "
          result = puppet_eval(input)
          @last_item = result
          output = normalize_output(result)
          ap(output)
        rescue ArgumentError => e
          puts e.message
        rescue Puppet::ResourceError => e
          puts e.message
        rescue Puppet::ParseErrorWithIssue => e
          puts e.message
        rescue Exception => e
          puts e.message
        end
      end
    end

    def self.print_repl_desc
      puts(<<-EOT)
Ruby Version: #{RUBY_VERSION}
Puppet Version: #{Puppet.version}
Puppet Repl Version: #{PuppetRepl::VERSION}
Created by: NWOps <corey@nwops.io>
Type "exit", "functions", "vars", "krt", "facts", "reset", "help" for more information.

      EOT
    end

    def self.start
      print_repl_desc
      repl_obj = new
      while buf = Readline.readline(">> ", true)
        repl_obj.handle_input(buf)
      end
    end
  end
end
