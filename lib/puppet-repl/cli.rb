require 'puppet'
require 'puppet/pops'
require "readline"

module PuppetRepl
  class Cli

    # returns a future parser for evaluating code
    def parser
      @parser || ::Puppet::Pops::Parser::EvaluatingParser.new
    end

    def module_dirs
      Puppet.settings[:basemodulepath].split(':')
    end

    # creates a puppet environment given a module path and environment name
    def puppet_environment
      @puppet_environment ||= Puppet::Node::Environment.create('production', module_dirs)
    end

    def scope
      unless @scope
        begin
          Puppet.initialize_settings
        rescue
          # do nothing otherwise calling init twice raises an error
        end
        #options['parameters']
        #options['facts']
        #options[:classes]
        node_name = 'node_name'
        node = Puppet::Node.new(node_name, :environment => puppet_environment)
        compiler = Puppet::Parser::Compiler.new(node)
        @scope = Puppet::Parser::Scope.new(compiler)
        @scope.source = Puppet::Resource::Type.new(:node, node_name)
        @scope.parent = compiler.topscope
      end
      @scope
    end

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
      items = [result].flatten
      output = items.map do |r|
        "#{r}"
      end
      if items.count > 1
        "\n" + output.join("\n")
      else
        output.join("\n")
      end
    end

    def handle_input(input)
      case input
      when 'help'
        PuppetRepl::Cli.print_repl_desc
      when 'functions'
        puts "list of functions coming soon"
      when 'types'
        puts "list of types coming soon"
      when '_'
        puts(" => #{@last_item}")
      when 'exit'
        exit 0
      when 'reset'
        @scope = nil
      else
        result = puppet_eval(input)
        @last_item = result
        puts(" => #{normalize_output(result)}")
      end
    end

    def self.ripl_start
      Ripl.start
    end

    def self.print_repl_desc
      puts(<<-EOT)
Puppet Version: #{Puppet.version}
Puppet Repl Version: #{PuppetRepl::VERSION}
Created by: NWOps <corey@nwops.io>
Type "exit", "functions", "types", "reset", "help" for more information.

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
