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
      comp = Proc.new {|s| key_words.grep(/^#{Regexp.escape(s)}/) }
      Readline.completion_append_character = ""
      Readline.completion_proc = comp
    end

    # returns a cached list of key words
    def key_words
      # because dollar signs don't work we can't display a $ sign in the keyword
      # list so its not explicitly clear what the keyword
      variables = scope.to_hash.keys
      # prepend a :: to topscope variables
      scoped_vars = variables.map { |k,v| scope.compiler.topscope.exist?(k) ? "::#{k}" : k }
      # append a () to functions so we know they are functions
      funcs = function_map.keys.map { |k| "#{k.split('::').last}()"}
      (scoped_vars + funcs + static_responder_list).uniq.sort
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
      case input
      when /^play|^facts|^vars|^functions|^classes|^resources|^krt|^environment|^reset|^help/
        args = input.split(' ')
        command = args.shift.to_sym
        if self.respond_to?(command)
          self.send(command, args)
        end
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

    def self.print_repl_desc
      puts(<<-EOT)
Ruby Version: #{RUBY_VERSION}
Puppet Version: #{Puppet.version}
Puppet Repl Version: #{PuppetRepl::VERSION}
Created by: NWOps <corey@nwops.io>
Type "exit", "functions", "vars", "krt", "facts", "resources", "classes",
     "play","reset", or "help" for more information.

      EOT
    end

    def read_loop
      while buf = Readline.readline(">> ", true)
        handle_input(buf)
      end
    end

    # start reads from stdin or from a file
    # if from stdin, the repl will process the input and exit
    # if from a file, the repl will process the file and continue to prompt
    # @param [Scope] puppet scope object
    def self.start(options={:scope => nil})
      opts = Trollop::options do
        opt :play, "Url or file to load from", :required => false, :type => String
        opt :run_once, "Evaulate and quit", :required => false, :default => false
      end
      options = opts.merge(options)
      print_repl_desc
      repl_obj = new
      repl_obj.initialize_from_scope(options[:scope])
      if options[:play]
        repl_obj.play_back(opts)
      # when the user supplied a file name without using the args (stdin)
      elsif ARGF.filename != "-"
        path = File.expand_path(ARGF.filename)
        repl_obj.play_back(:play => path)
      # when the user supplied a file content using stdin, aka. cat,pipe,echo or redirection
      elsif ARGF.filename == "-" and (not STDIN.tty? and not STDIN.closed?)
        input = ARGF.read
        repl_obj.handle_input(input)
      end
      # helper code to make tests exit the loop
      unless options[:run_once]
        repl_obj.read_loop
      end
    end
  end
end
