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

    def handle_input(input)
      case input
      when 'help'
        PuppetRepl::Cli.print_repl_desc
      when 'functions'
        puts function_map.keys.sort
      when 'facts'
        puts JSON.pretty_generate(node.facts)
      when '_'
        puts(" => #{@last_item}")
      when 'environment'
        puts "Puppet Environment: #{puppet_env_name}"
      when 'exit'
        exit 0
      when 'reset'
        @scope = nil
      when 'current_resources'
        compiler.known_resource_types
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
Type "exit", "functions", "facts", "reset", "help" for more information.

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
