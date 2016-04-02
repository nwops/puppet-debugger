require 'puppet'
require 'readline'
require 'json'
require_relative 'support'
module PuppetRepl
  class Cli
    include PuppetRepl::Support

    def puppet_eval(input)
      begin
        parser.evaluate_string(scope, input)
      rescue ArgumentError => e
        e.message
      rescue Puppet::ParseErrorWithIssue => e
        e.message
      rescue Exception => e
        e.message
      end
    end

    def normalize_output(result)
      if result.instance_of?(Array)
        if result.count == 1
          return result.first
        end
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
      when 'exit'
        exit 0
      when 'reset'
        @scope = nil
      when 'krt'
        ap(known_resource_types, {:sort_keys => true, :indent => -1})
      else
        result = puppet_eval(input)
        @last_item = result
        puts(" => #{normalize_output(result)}")
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
