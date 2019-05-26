# frozen_string_literal: true

require "puppet"
require "readline"
require "json"
require "puppet-debugger/support"
require "pluginator"
require "puppet-debugger/hooks"
require "forwardable"
require "plugins/puppet-debugger/input_responders/functions"
require "plugins/puppet-debugger/input_responders/datatypes"
require 'tty-pager'
module PuppetDebugger
  class Cli
    include PuppetDebugger::Support
    extend Forwardable
    attr_accessor :settings, :log_level, :in_buffer, :out_buffer, :html_mode, :extra_prompt, :bench
    attr_reader :source_file, :source_line_num, :hooks
    def_delegators :hooks, :exec_hook, :add_hook, :delete_hook
    OUT_SYMBOL = ' => '
    def initialize(options = {})
      do_initialize if Puppet[:codedir].nil?
      Puppet.settings[:name] = :debugger
      Puppet[:static_catalogs] = false unless Puppet.settings[:static_catalogs].nil?
      set_remote_node_name(options[:node_name])
      initialize_from_scope(options[:scope])
      set_catalog(options[:catalog])
      @log_level = "notice"
      @out_buffer = options[:out_buffer] || $stdout
      @html_mode = options[:html_mode] || false
      @source_file = options[:source_file] || nil
      @source_line_num = options[:source_line] || nil
      @in_buffer = options[:in_buffer] || $stdin
      Readline.input = @in_buffer
      Readline.output = @out_buffer
      Readline.completion_append_character = ""
      Readline.basic_word_break_characters = " "
      Readline.completion_proc = command_completion
      AwesomePrint.defaults = {
        html: @html_mode,
        sort_keys: true,
        indent: 2,
      }
    end

    # @return [Proc] the proc used in the command completion for readline
    # if a plugin keyword is found lets return keywords using the plugin's command completion
    # otherwise return the default set of keywords and filter out based on input
    def command_completion
      proc do |input|
        words = Readline.line_buffer.split(Readline.basic_word_break_characters)
        next key_words.grep(/^#{Regexp.escape(input)}/) if words.empty?

        first_word = words.shift
        plugins = PuppetDebugger::InputResponders::Commands.plugins.find_all do |p|
          p::COMMAND_WORDS.find { |word| word.start_with?(first_word) }
        end
        if plugins.count == 1 and /\A#{first_word}\s/.match(Readline.line_buffer)
          plugins.first.command_completion(words)
        else
          key_words.grep(/^#{Regexp.escape(input)}/)
        end
      end
    end

    def hooks
      @hooks ||= PuppetDebugger::Hooks.new
    end

    # returns a cached list of key words
    def key_words
      # because dollar signs don't work we can't display a $ sign in the keyword
      # list so its not explicitly clear what the keyword
      variables = scope.to_hash.keys
      # prepend a :: to topscope variables
      scoped_vars = variables.map { |k, _v| scope.compiler.topscope.exist?(k) ? "$::#{k}" : "$#{k}" }
      PuppetDebugger::InputResponders::Functions.instance.debugger = self
      funcs = PuppetDebugger::InputResponders::Functions.instance.func_list
      PuppetDebugger::InputResponders::Datatypes.instance.debugger = self
      (scoped_vars + funcs + static_responder_list + PuppetDebugger::InputResponders::Datatypes.instance.all_data_types).uniq.sort
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

    #
    # @return [Array] - returns a formatted array
    # @param types [Array] - an array or string
    def expand_resource_type(types)
      Array(types).flatten.map { |t| contains_resources?(t) ? to_resource_declaration(t) : t }
    end

    def contains_resources?(result)
      !Array(result).flatten.find { |r| r.class.to_s =~ /Puppet::Pops::Types::PResourceType/ }.nil?
    end

    def normalize_output(result)
      if contains_resources?(result)
        output = expand_resource_type(result)
        # the results might be wrapped into an array
        # if the only output is a resource then return it
        # otherwise it is multiple items or an actually array
        return output.first if output.count == 1

        return output
      end
      result
    end

    def responder_list
      plugins = Pluginator.find(PuppetDebugger)
    end

    # @return [TTY::Pager] the pager object, disable if CI or testing is present
    def pager
      @pager ||= TTY::Pager.new(output: out_buffer, enabled: ENV['CI'].nil? )
    end

    # @param output [String] - the content to output
    # @summary outputs the output to the output buffer
    #   uses the pager if the screen height is less than the height of the 
    #   output content
    #   Disabled if CI or testing is being done
    def handle_output(output)
      if output.lines.count >= TTY::Screen.height && ENV['CI'].nil?
        output << "\n"
        pager.page(output)
      else
        out_buffer.puts(output) unless output.empty?
      end
    end

    # this method handles all input and expects a string of text.
    # @param input [String] - the input content to parse or run 
    def handle_input(input)
      raise ArgumentError unless input.instance_of?(String)

      output = begin
        case input.strip
        when PuppetDebugger::InputResponders::Commands.command_list_regex
          args = input.split(" ")
          command = args.shift
          plugin = PuppetDebugger::InputResponders::Commands.plugin_from_command(command)
          plugin.execute(args, self) || ""
        when "_"
          " => #{@last_item}"
        else
          result = puppet_eval(input)
          @last_item = result
          o = normalize_output(result)
          o.nil? ? "" : o.ai
        end
      rescue PuppetDebugger::Exception::InvalidCommand => e
        e.message.fatal
      rescue LoadError => e
        e.message.fatal
      rescue Errno::ETIMEDOUT => e
        e.message.fatal
      rescue ArgumentError => e
        e.message.fatal
      rescue Puppet::ResourceError => e
        e.message.fatal
      rescue Puppet::Error => e
        e.message.fatal
      rescue Puppet::ParseErrorWithIssue => e
        e.message.fatal
      rescue PuppetDebugger::Exception::FatalError => e
        handle_output(e.message.fatal)
        exit 1 # this can sometimes causes tests to fail
      rescue PuppetDebugger::Exception::Error => e
        e.message.fatal
      rescue ::RuntimeError => e
        handle_output(e.message.fatal)
        exit 1
      end
      output = OUT_SYMBOL + output unless output.empty?
      handle_output(output)
      exec_hook :after_output, out_buffer, self, self
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
    # @return [Boolean] - return true if this is a multiline input, false otherwise
    def multiline_input?(e)
      case e.message
      when /Syntax error at end of/i
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
      full_buffer = ""
      while buf = Readline.readline("#{line_number}:#{extra_prompt}>> ", true)
        begin
          full_buffer += buf
          # unless this is puppet code, otherwise skip repl keywords
          unless PuppetDebugger::InputResponders::Commands.command_list_regex.match(buf)
            line_number = line_number.next
            begin
              parser.parse_string(full_buffer)
            rescue Puppet::ParseErrorWithIssue => e
              if multiline_input?(e)
                out_buffer.print "  "
                full_buffer += "\n"
                next
              end
            end
          end
          handle_input(full_buffer)
          full_buffer = ""
        end
      end
    end

    # used to start a debugger session without attempting to read from stdin
    # or
    # this is primarily used by the debug::break() module function and the puppet debugger face
    # @param [Hash] must contain at least the puppet scope object
    # @option play [String] - must be a path to a file
    # @option content [String] - play back the string content passed in
    # @option source_file [String] - the file from which the breakpoint was used
    # @option source_line [Integer] - the line in the sourcefile from which the breakpoint was used
    # @option in_buffer [IO] - the input buffer to read from
    # @option out_buffer [IO] - the output buffer to write to
    # @option scope [Scope] - the puppet scope
    def self.start_without_stdin(options = { scope: nil })
      options[:play] = options[:play].path if options[:play].respond_to?(:path)
      repl_obj = PuppetDebugger::Cli.new(options)
      repl_obj.out_buffer.puts print_repl_desc unless options[:quiet]
      repl_obj.handle_input(options[:content]) if options[:content]
      # TODO: make the output optional so we can have different output destinations
      repl_obj.handle_input("whereami") if options[:source_file] && options[:source_line]
      repl_obj.handle_input("play #{options[:play]}") if options[:play]
      repl_obj.read_loop unless options[:run_once]
    end

    # start reads from stdin or from a file
    # if from stdin, the repl will process the input and exit
    # if from a file, the repl will process the file and continue to prompt
    # @param [Hash] puppet scope object
    def self.start(options = { scope: nil })
      opts = Trollop.options do
        opt :play, "Url or file to load from", required: false, type: String
        opt :run_once, "Evaluate and quit", required: false, default: false
        opt :node_name, "Remote Node to grab facts from", required: false, type: String
        opt :catalog, "Import a catalog file to inspect", required: false, type: String
        opt :quiet, "Do not display banner", required: false, default: false
      end
      if !STDIN.tty? && !STDIN.closed?
        options[:run_once] = true 
        options[:quiet] = true
      end
      options = opts.merge(options)
      options[:play] = options[:play].path if options[:play].respond_to?(:path)
      repl_obj = PuppetDebugger::Cli.new(options)
      repl_obj.out_buffer.puts print_repl_desc unless options[:quiet]
      if options[:play]
        repl_obj.handle_input("play #{options[:play]}")
      elsif (ARGF.filename == "-") && (!STDIN.tty? && !STDIN.closed?)
        # when the user supplied a file content using stdin, aka. cat,pipe,echo or redirection
        input = ARGF.read
        repl_obj.handle_input(input)
      elsif ARGF.filename != "-"
        # when the user supplied a file name without using the args (stdin)
        path = File.expand_path(ARGF.filename)
        repl_obj.handle_input("play #{path}")
      end
      # helper code to make tests exit the loop
      repl_obj.read_loop unless options[:run_once]
    end
  end
end
