require 'puppet'
require 'readline'
require 'json'
require_relative 'support'

module PuppetRepl
  class Cli
    include PuppetRepl::Support

    attr_accessor :settings, :log_level

    def initialize
      @log_level = 'notice'
    end

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

    def set_log_level(level)
      Puppet::Util::Log.level = level.to_sym
      Puppet::Util::Log.newdestination(:console)
    end

    def handle_set(input)
      args = input.split(' ')
      args.shift # throw away the set
      case args.shift
      when /loglevel/
        if level = args.shift
          @log_level = level
          set_log_level(level)
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
        # convert symbols to keys
        vars = node.facts.values
        ap(vars, {:sort_keys => true, :indent => -1})
      when '_'
        puts(" => #{@last_item}")
      when 'vars'
        # remove duplicate variables that are also in the facts hash
        vars = scope.to_hash.delete_if {| key, value | node.facts.values.key?(key) }
        vars['facts'] = 'removed by the puppet-repl' if vars.key?('facts')
        ap 'Facts were removed for easier viewing'
        ap(vars, {:sort_keys => true, :indent => -1})
      when 'environment'
        puts "Puppet Environment: #{puppet_env_name}"
      when 'exit'
        exit 0
      when 'reset'
        set_scope(nil)
        # initilize scope again
        scope
        set_log_level(log_level)
      when 'krt'
        ap(known_resource_types, {:sort_keys => true, :indent => -1})
      else
        begin
          result = puppet_eval(input)
          @last_item = result
          print " => "
          output = normalize_output(result)
          if output.nil?
            puts ""
          else
            ap(output)
          end
        rescue ArgumentError => e
          print " => "
          puts e.message.fatal
        rescue Puppet::ResourceError => e
          print " => "
          puts e.message.fatal
        rescue Puppet::ParseErrorWithIssue => e
          print " => "
          puts e.message.fatal
        rescue Exception => e
          puts e.message.fatal
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

    def self.start(scope=nil)
      print_repl_desc
      repl_obj = new
      repl_obj.initialize_from_scope(scope)
      while buf = Readline.readline(">> ", true)
        repl_obj.handle_input(buf)
      end
    end
  end
end
