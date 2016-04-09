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
      elsif result.instance_of?(Puppet::Pops::Types::PResourceType)
        return to_resource_declaration(result)
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
      if self.respond_to?(input.to_sym)
        self.send(input.to_sym)
      else
        case input
        when /exit/
          exit 0
        when /^:set/
          handle_set(input)
        when '_'
          puts(" => #{@last_item}")
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
    end

    def self.print_repl_desc
      puts(<<-EOT)
Ruby Version: #{RUBY_VERSION}
Puppet Version: #{Puppet.version}
Puppet Repl Version: #{PuppetRepl::VERSION}
Created by: NWOps <corey@nwops.io>
Type "exit", "functions", "vars", "krt", "facts", "resources", "classes",
     "reset", or "help" for more information.

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
