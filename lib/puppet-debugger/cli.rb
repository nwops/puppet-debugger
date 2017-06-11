# frozen_string_literal: true

require 'puppet'
require 'readline'
require 'json'
require_relative 'support'
require 'pluginator'

module PuppetDebugger
  class Cli
    include PuppetDebugger::Support

    attr_accessor :settings, :log_level, :in_buffer, :out_buffer, :html_mode, :extra_prompt, :bench
    attr_reader :source_file, :source_line_num

    def initialize(options = {})
      do_initialize if Puppet[:codedir].nil?
      Puppet.settings[:name] = :debugger
      Puppet.settings[:trusted_server_facts] = true unless Puppet.settings[:trusted_server_facts].nil?
      Puppet[:static_catalogs] = false unless Puppet.settings[:static_catalogs].nil?
      set_remote_node_name(options[:node_name])
      initialize_from_scope(options[:scope])
      @log_level = 'notice'
      @out_buffer = options[:out_buffer] || $stdout
      @html_mode = options[:html_mode] || false
      @source_file = options[:source_file] || nil
      @source_line_num = options[:source_line] || nil
      @in_buffer = options[:in_buffer] || $stdin
      comp = proc do |s|
        key_words.grep(/^#{Regexp.escape(s)}/)
      end
      Readline.completion_append_character = ''
      Readline.basic_word_break_characters = ' '
      Readline.completion_proc = comp
      AwesomePrint.defaults = {
        html: @html_mode,
        sort_keys: true,
        indent: 2
      }
    end

    # returns a cached list of key words
    def key_words
      # because dollar signs don't work we can't display a $ sign in the keyword
      # list so its not explicitly clear what the keyword
      variables = scope.to_hash.keys
      # prepend a :: to topscope variables
      scoped_vars = variables.map { |k, _v| scope.compiler.topscope.exist?(k) ? "$::#{k}" : "$#{k}" }
      # append a () to functions so we know they are functions
      funcs = function_map.keys.map { |k| "#{k.split('::').last}()" }
      (scoped_vars + funcs + static_responder_list + all_data_types).uniq.sort
    end

    # looks up the type in the catalog by using the type and title
    # and returns the resource in ral format
    def to_resource_declaration(type)
      if type.respond_to?(:type_name) && type.respond_to?(:title)
        title = type.title
        type_name = type.type_name
      elsif type_result = /(\w+)\['?(\w+)'?\]/.match(type.to_s)
        # not all types have a type_name and title so we
        # output to a string and parse the results
        title = type_result[2]
        type_name = type_result[1]
      else
        return type
      end
      res = scope.catalog.resource(type_name, title)
      return res.to_ral if res
      # don't return anything or returns nil if item is not in the catalog
    end

    # returns a formatted array
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
        return output.first if output.count == 1
        return output
      elsif result.class.to_s =~ /Puppet::Pops::Types/
        return to_resource_declaration(result)
      end
      result
    end

    def responder_list
      plugins = Pluginator.find(PuppetDebugger)
    end

    # this method handles all input and expects a string of text.
    #
    def handle_input(input)
      raise ArgumentError unless input.instance_of?(String)
      begin
        output = ''
        case input.strip
        when PuppetDebugger::InputResponders::Commands.command_list_regex
          args = input.split(' ')
          command = args.shift
          plugin = PuppetDebugger::InputResponders::Commands.plugin_from_command(command)
          output = plugin.execute(args, self)
          return out_buffer.puts output
        when '_'
          output = " => #{@last_item}"
        else
          result = puppet_eval(input)
          @last_item = result
          output = normalize_output(result)
          output = output.nil? ? '' : output.ai
        end
      rescue PuppetDebugger::Exception::InvalidCommand => e
        output = e.message.fatal
      rescue LoadError => e
        output = e.message.fatal
      rescue Errno::ETIMEDOUT => e
        output = e.message.fatal
      rescue ArgumentError => e
        output = e.message.fatal
      rescue Puppet::ResourceError => e
        output = e.message.fatal
      rescue Puppet::Error => e
        output = e.message.fatal
      rescue Puppet::ParseErrorWithIssue => e
        output = e.message.fatal
      rescue PuppetDebugger::Exception::FatalError => e
        output = e.message.fatal
        out_buffer.puts output
        exit 1 # this can sometimes causes tests to fail
      rescue PuppetDebugger::Exception::Error => e
        output = e.message.fatal
      end
      unless output.empty?
        out_buffer.print ' => '
        out_buffer.puts output unless output.empty?
      end
    end

    def self.print_repl_desc
      output = <<-EOT
Ruby Version: #{RUBY_VERSION}
Puppet Version: #{Puppet.version}
Puppet Debugger Version: #{PuppetDebugger::VERSION}
Created by: NWOps <corey@nwops.io>
Type "commands" for a list of debugger commands
or "help" to show the help screen.


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
      while buf = Readline.readline("#{line_number}:#{extra_prompt}>> ", true)
        begin
          full_buffer += buf
          # unless this is puppet code, otherwise skip repl keywords
          unless PuppetDebugger::InputResponders::Commands.command_list_regex.match(buf)
            line_number = line_number.next
            parser.parse_string(full_buffer)
          end
        rescue Puppet::ParseErrorWithIssue => e
          if multiline_input?(e)
            out_buffer.print '  '
            full_buffer += "\n"
            next
          end
        end
        handle_input(full_buffer)
        full_buffer = ''
      end
    end

    # used to start a debugger session without attempting to read from stdin
    # or
    # this is primarily used by the debug::break() module function and the puppet debugger face
    # @param [Hash] must contain at least the puppet scope object
    # @option play - must be a path string
    def self.start_without_stdin(options = { scope: nil })
      puts print_repl_desc unless options[:quiet]
      repl_obj = PuppetDebugger::Cli.new(options)
      options[:play] = options[:play].path if options[:play].respond_to?(:path)
      # TODO: make the output optional so we can have different output destinations
      repl_obj.handle_input('whereami') if options[:source_file] && options[:source_line]
      repl_obj.handle_input("play #{options[:play]}") if options[:play]
      repl_obj.read_loop unless options[:run_once]
    end

    # start reads from stdin or from a file
    # if from stdin, the repl will process the input and exit
    # if from a file, the repl will process the file and continue to prompt
    # @param [Hash] puppet scope object
    def self.start(options = { scope: nil })
      opts = Trollop.options do
        opt :play, 'Url or file to load from', required: false, type: String
        opt :run_once, 'Evaluate and quit', required: false, default: false
        opt :node_name, 'Remote Node to grab facts from', required: false, type: String
        opt :quiet, 'Do not display banner', required: false, default: false
      end
      options = opts.merge(options)
      puts print_repl_desc unless options[:quiet]
      options[:play] = options[:play].path if options[:play].respond_to?(:path)
      repl_obj = PuppetDebugger::Cli.new(options)
      if options[:play]
        repl_obj.handle_input("play #{options[:play]}")
      elsif ARGF.filename != '-'
        # when the user supplied a file name without using the args (stdin)
        path = File.expand_path(ARGF.filename)
        repl_obj.handle_input("play #{path}")
      elsif (ARGF.filename == '-') && (!STDIN.tty? && !STDIN.closed?)
        # when the user supplied a file content using stdin, aka. cat,pipe,echo or redirection
        input = ARGF.read
        repl_obj.handle_input(input)
      end
      # helper code to make tests exit the loop
      repl_obj.read_loop unless options[:run_once]
    end
  end
end
