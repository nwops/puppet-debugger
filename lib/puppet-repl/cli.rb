require 'puppet'
require 'readline'
require 'json'
require_relative 'support'

module PuppetRepl
  class Cli
    include PuppetRepl::Support

    attr_accessor :settings, :log_level, :in_buffer, :out_buffer, :html_mode

    def initialize(options={})
      @log_level = 'notice'
      @out_buffer = options[:out_buffer] || $stdout
      @html_mode = options[:html_mode] || false
      @in_buffer = options[:in_buffer] || $stdin
      comp = Proc.new do |s|
        key_words.grep(/^#{Regexp.escape(s)}/)
      end
      Readline.completion_append_character = ""
      Readline.basic_word_break_characters = " "

      Readline.completion_proc = comp
      AwesomePrint.defaults = {
        :html => @html_mode,
        :sort_keys => true,
        :indent => 2
      }
      do_initialize
    end

    # returns a cached list of key words
    def key_words
      # because dollar signs don't work we can't display a $ sign in the keyword
      # list so its not explicitly clear what the keyword
      variables = scope.to_hash.keys
      # prepend a :: to topscope variables
      scoped_vars = variables.map { |k,v| scope.compiler.topscope.exist?(k) ? "$::#{k}" : "$#{k}" }
      # append a () to functions so we know they are functions
      funcs = function_map.keys.map { |k| "#{k.split('::').last}()"}
      (scoped_vars + funcs + static_responder_list).uniq.sort
    end

    def puppet_eval(input)
      parser.evaluate_string(scope, input)
    end

    # looks up the type in the catalog by using the type and title
    # and returns the resource in ral format
    def to_resource_declaration(type)
      if type.respond_to?(:type_name) and type.respond_to?(:title)
        title = type.title
        type_name = type.type_name
      else
        # not all types have a type_name and title so we
        # output to a string and parse the results
        type_result = /(\w+)\['?(\w+)'?\]/.match(type.to_s)
        title = type_result[2]
        type_name = type_result[1]
      end
      res = scope.catalog.resource(type_name, title)
      if res
        return res.to_ral
      end
      # don't return anything or returns nil if item is not in the catalog
    end

    # ruturns a formatted array
    def expand_resource_type(types)
      output = [types].flatten.map do |t|
        if t.class.to_s =~ /Puppet::Pops::Types/
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
      elsif result.class.to_s =~ /Puppet::Pops::Types/
        return to_resource_declaration(result)
      end
      result
    end

    # this method handles all input and expects a string of text.
    #
    def handle_input(input)
        raise ArgumentError unless input.instance_of?(String)
        begin
          output = ''
          case input
          when /^play|^classification|^facts|^vars|^functions|^classes|^resources|^krt|^environment|^reset|^help/
            args = input.split(' ')
            command = args.shift.to_sym
            if self.respond_to?(command)
              output = self.send(command, args)
            end
            return out_buffer.puts output
          when /exit/
            exit 0
          when /^:set/
            output = handle_set(input)
          when '_'
            output = " => #{@last_item}"
          else
            result = puppet_eval(input)
            @last_item = result
            output = normalize_output(result)
            if output.nil?
              output = ""
            else
              output = output.ai
            end
          end
        rescue LoadError => e
          output = e.message.fatal
        rescue Errno::ETIMEDOUT => e
          output = e.message.fatal
        rescue ArgumentError => e
          output = e.message.fatal
        rescue Puppet::ResourceError => e
          output = e.message.fatal
        rescue Puppet::ParseErrorWithIssue => e
          output = e.message.fatal
        rescue PuppetRepl::Exception::FatalError => e
          output = e.message.fatal
          out_buffer.puts output
          exit 1
        rescue PuppetRepl::Exception::Error => e
          output = e.message.fatal
        end
        out_buffer.print " => "
        out_buffer.puts output
    end

    def self.print_repl_desc
      output = <<-EOT
Ruby Version: #{RUBY_VERSION}
Puppet Version: #{Puppet.version}
Puppet Repl Version: #{PuppetRepl::VERSION}
Created by: NWOps <corey@nwops.io>
Type "exit", "functions", "vars", "krt", "facts", "resources", "classes",
     "play", "classification", "reset", or "help" for more information.

      EOT
      output
    end

    # tries to determine if the input is going to be a multiline input
    # by reading the parser error message
    def multiline_input?(e)
      case e.message
      when /Syntax error at end of file/i
        true
      else
        false
      end
    end

    # reads input from stdin, since readline requires a tty
    # we cannot read from other sources as readline requires a file object
    # we parse the string after each input to determine if the input is a multiline_input
    # entry.  If it is multiline we run through the loop again and concatenate the
    # input
    def read_loop
      line_number = 1
      full_buffer = ''
      while buf = Readline.readline("#{line_number}:>> ", true)
        begin
          full_buffer += buf
          # unless this is puppet code, otherwise skip repl keywords
          unless keyword_expression.match(buf)
            line_number = line_number.next
            parser.parse_string(full_buffer)
          end
        rescue Puppet::ParseErrorWithIssue => e
          if multiline_input?(e)
            out_buffer.print '  '
            next
          end
        end
        handle_input(full_buffer)
        full_buffer = ''
      end
    end

    # start reads from stdin or from a file
    # if from stdin, the repl will process the input and exit
    # if from a file, the repl will process the file and continue to prompt
    # @param [Scope] puppet scope object
    def self.start(options={:scope => nil})
      opts = Trollop::options do
        opt :play, "Url or file to load from", :required => false, :type => String
        opt :run_once, "Evaluate and quit", :required => false, :default => false
        opt :node_name, "Remote Node to grab facts from", :required => false, :type => String
      end
      options = opts.merge(options)
      puts print_repl_desc
      repl_obj = new
      repl_obj.remote_node_name = opts[:node_name] if opts[:node_name]
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
